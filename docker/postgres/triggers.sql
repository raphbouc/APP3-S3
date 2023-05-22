CREATE OR REPLACE FUNCTION procedure_reserv_update() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF EXISTS (
            SELECT 1
            FROM reservation res
            WHERE res.id_locaux = NEW.id_locaux
                AND res.date_debut < NEW.date_fin
                AND res.date_fin > NEW.date_debut
                AND res.id_reservation <> NEW.id_reservation
                AND res.id_pavillon = NEW.id_pavillon
        )
        THEN
            RAISE EXCEPTION 'Conflit dans la reservation : L interval de temps choisi chevauche une reservation existante.';
        END IF;

        INSERT INTO log(id_log, description, date, id_reservation, cip)
        VALUES(DEFAULT, 'Reservation creee', CURRENT_DATE, new.id_reservation, new.cip);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
            IF EXISTS (
                SELECT 1
                FROM reservation res
                WHERE res.id_locaux = NEW.id_locaux
                    AND res.id_pavillon = NEW.id_pavillon
                    AND res.date_debut < NEW.date_fin
                    AND res.date_fin > NEW.date_debut
                    AND res.id_reservation <> NEW.id_reservation
            )
            THEN
            RAISE EXCEPTION 'Conflit dans la reservation : L interval de temps choisi chevauche une reservation existante.';
            END IF;

            UPDATE log
            SET description = 'Update de la reservation', date = CURRENT_DATE
            WHERE id_reservation = new.id_reservation;

            RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_reservation_update ON reservation;
DROP TRIGGER IF EXISTS trigger_reservation_delete ON reservation;

CREATE OR REPLACE FUNCTION procedure_reservation_delete()
    RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO log(id_log,description, date, cip, id_reservation)
        VALUES(DEFAULT,'Reservation retire', CURRENT_DATE, new.cip, new.id_reservation);
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_reservation_update
    AFTER INSERT OR UPDATE ON reservation
    FOR EACH ROW
EXECUTE PROCEDURE procedure_reserv_update();

CREATE TRIGGER trigger_reservation_delete
    BEFORE DELETE
    ON reservation
    FOR EACH ROW EXECUTE PROCEDURE procedure_reservation_delete();