CREATE DATABASE IF NOT EXISTS web_app;

CREATE USER test_user WITH PASSWORD 'QWERTY';

GRANT ALL privileges ON DATABASE web_app TO test_user;

CREATE SEQUENCE user_ids;
CREATE SEQUENCE status_ids;

CREATE TABLE user_status (
    id integer DEFAULT nextval('status_ids'::regclass) NOT NULL,
    status text
);

ALTER TABLE public.user_status OWNER TO test_user;
ALTER TABLE ONLY user_status
    ADD CONSTRAINT user_status_pkey PRIMARY KEY (id);

CREATE TABLE users (
    id integer DEFAULT nextval('user_ids'::regclass) NOT NULL,
    name text,
    fam text,
    phone character(10),
    status_id integer,
    reg_time timestamp without time zone
);

ALTER TABLE public.users OWNER TO test_user;
ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
ALTER TABLE ONLY users
    ADD CONSTRAINT users_status_id_fkey FOREIGN KEY (status_id) REFERENCES user_status(id);
