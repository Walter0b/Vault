create extension if not exists "uuid-ossp";


-- delete all tables and types
-- Suppression des tables qui ont des clés étrangères
drop table if exists public.notification cascade;
drop table if exists public.country cascade;
drop table if exists public.transaction cascade;
drop table if exists public.validation cascade;
drop table if exists public.proof cascade;
drop table if exists public.file cascade;
drop table if exists public.trip cascade;
drop table if exists public.customer cascade;
drop table if exists public.customer_type cascade;
drop table if exists public.rate_currency cascade;
drop table if exists public.currency cascade;
drop table if exists public.bank cascade;
drop table if exists public.alert_template cascade;
drop table if exists public.rule cascade;
drop table if exists public.rule_condition cascade;
drop table if exists public.transaction_beta cascade;
drop table if exists public.category cascade;

-- Deletion of enumerated types
drop type if exists public.trip_status;
drop type if exists public.alert_status;
drop type if exists public.balance_flag_type;
drop type if exists public.notification_type;
drop type if exists public.bank_condition_operator;
drop type if exists public.bank_rule_target;
drop type if exists public.bank_validity_time;
drop type if exists public.card_type;


-- Custome type creation
create type public.trip_status as enum ('on_hold', 'in_progress', 'ended');
create type public.balance_flag_type as enum ('green', 'orange', 'red');
create type public.alert_type as enum ('formal_notice', 'new_customer', 'new_trip', 'flag_updated',  
                                        'ended_trip', 'suspended_card', 'proof_accepted', 'proof_rejected');
create type public.bank_condition_operator as enum ('=', '<', '>', '<=', '>=', '!=');
create type public.bank_rule_target as enum ('trip', 'balance_flag', 'formal_notice_undeclared_trip', 
                    'formal_notice_threshold_exceeded_outside', 'formal_notice_threshold_exceeded_online');
create type public.bank_validity_time as enum ('permanent', 'period');
create type public.card_type as enum ( 'debit', 'credit', 'prepaid', 'debit_differed',
                'withdrawal', 'international+visa', 'international+mastercard', 'international+amex', 
                'international+discover', 'international+unionpay', 'virtual' );
create type public.alert_status as enum ('pending', 'sent', 'failed');

-- Create custom tables

create table if not exists public.bank
(
    id      uuid    default uuid_generate_v4() not null primary key,
    name             varchar                            not null unique,
    address          varchar,
    city             varchar(50),
    country          varchar(50),
    logo             bytea,
    phone            varchar(20),
    email            varchar(100) not null unique,
    thresold_outside         numeric(10, 4) default 5000000.00 not null,
    thresold_online          numeric(10, 4) default 1000000.00 not null,
    created_at  timestamptz          default current_timestamp not null,
    updated_at  timestamptz          default current_timestamp not null,
    created_by  uuid,
    updated_by  uuid,

    constraint valid_phone
        check ( phone ~ '^[0-9]{10,20}$' ),
    constraint valid_email
        check ( email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' ),
    constraint thresold_positive
            check ( thresold_outside > 0 and thresold_online > 0)
);

------------------------------------------------------------------
------------------------------------------------------------------

create table if not exists public.currency
(
    id      uuid    default uuid_generate_v4() not null primary key,
    code             varchar(3)                         not null unique,
    number           varchar(3)                         not null unique,
    name             varchar                            not null unique,
    symbol           varchar,
    created_at  timestamptz          default current_timestamp not null,
    updated_at  timestamptz          default current_timestamp not null,
    created_by  uuid,
    updated_by  uuid
);

comment on table public.currency is 'Currency';
comment on column public.currency.id is 'Currency Identifier';
comment on column public.currency.code is 'Currency Iso code';
comment on column public.currency.name is 'Currency Name';
comment on column public.currency.symbol is 'Currency Symbol if exist';

------------------------------------------------------------------
------------------------------------------------------------------

create table if not exists public.rate_currency
(
    id      uuid    default uuid_generate_v4() not null primary key,
    currency_id     uuid                     not null,
    rate    numeric(10, 4) not null,
    date             date                            not null,
    created_at  timestamptz          default current_timestamp not null,
    updated_at  timestamptz          default current_timestamp not null,
    created_by  uuid,
    updated_by  uuid,
    constraint currency_fk
        foreign key (currency_id) references public.currency(id)
        on update cascade on delete restrict,
    constraint rate_positive
            check ( rate > 0),
    constraint unique_rate_currency_date 
        unique (rate, currency_id, date)
    
);

------------------------------------------------------------------
------------------------------------------------------------------

create table if not exists public.customer_type
(
    id      uuid    default uuid_generate_v4() not null primary key,
    type            varchar(50)                        not null unique,
    description     text,
    created_at  timestamptz          default current_timestamp not null,
    updated_at  timestamptz          default current_timestamp not null,
    created_by  uuid,
    updated_by  uuid

);

------------------------------------------------------------------
------------------------------------------------------------------

create table if not exists public.customer
(
    id      uuid    default uuid_generate_v4() not null primary key,
    serial_number varchar(50) unique,
    customer_type_id    uuid,
    first_name            varchar(255),
    last_name             varchar(255),
    phone       varchar(20),
    email       varchar(100),
    balance_flag balance_flag_type default 'green' not null,
    created_at  timestamptz          default current_timestamp not null,
    updated_at  timestamptz          default current_timestamp not null,
    created_by  uuid,
    updated_by  uuid,

    constraint customer_type_fk
        foreign key (customer_type_id) references public.customer_type(id)
        on update cascade on delete set null,
    constraint valid_phone
        check ( phone ~ '^[0-9]{10,20}$' ),
    constraint valid_email
        check ( email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' )
);

------------------------------------------------------------------
------------------------------------------------------------------

create table if not exists public.category
(
    id      uuid    default uuid_generate_v4() not null primary key,
    type    varchar(50) not null,
    is_required boolean default true not null, -- Category is needed
    description     text,
    created_at  timestamptz          default current_timestamp not null,
    updated_at  timestamptz          default current_timestamp not null,
    created_by  uuid,
    updated_by  uuid
);
------------------------------------------------------------------
------------------------------------------------------------------

create table if not exists public.file
(
    id      uuid    default uuid_generate_v4() not null primary key,
    categrory_id uuid not null,
    directus_files_id  uuid,
    created_at  timestamptz          default current_timestamp not null,
    updated_at  timestamptz          default current_timestamp not null,
    created_by  uuid,
    updated_by  uuid,

    constraint categrory_fk
        foreign key (categrory_id) references public.category(id)
        on update cascade on delete restrict
);

------------------------------------------------------------------
------------------------------------------------------------------

create table if not exists public.trip
(
    id      uuid    default uuid_generate_v4() not null primary key,
    customer_id    uuid not null,
    manager_user    uuid,
    validator_user  uuid,
    title           text,
    start_date            date                      not null,
    end_date              date                      not null,
    status       trip_status    default 'on_hold'   not null,
    is_outside   boolean   default true  not null,
    origin       varchar(50),
    destination  varchar(50),
    proof_required boolean default true not null, -- is proof required?
    balance     numeric(10, 4) default 0 not null,
    created_at  timestamptz          default current_timestamp not null,
    updated_at  timestamptz          default current_timestamp not null,
    created_by  uuid,
    updated_by  uuid,

     constraint customer_fk
        foreign key (customer_id) references public.customer(id)
        on update cascade on delete restrict,
     constraint balance_positive
            check ( balance >= 0 )
);

------------------------------------------------------------------
------------------------------------------------------------------

create table if not exists public.country
(
    id      uuid    default uuid_generate_v4() not null primary key,
    number  varchar(3) not null unique,
    code_3  varchar(3) not null unique,
    code_2  varchar(2) not null unique,
    name  varchar(50) not null unique,
    created_at  timestamptz          default current_timestamp not null,
    updated_at  timestamptz          default current_timestamp not null,
    created_by  uuid,
    updated_by  uuid
);

------------------------------------------------------------------
------------------------------------------------------------------

create table if not exists public.transaction
(
    id      uuid    default uuid_generate_v4() not null primary key,
    trip_id     uuid not null,
    currency_id uuid not null,
    amount      numeric(10, 4)                            not null,
    reference varchar(50) unique,
    proof_required boolean default false not null, -- is proof required?
    country_id    uuid not null,
    date date not null,
    memo varchar,
    card_number varchar(30),
    branch_code varchar(20),
    card_type card_type default 'international+visa',
    created_at  timestamptz          default current_timestamp not null,
    updated_at  timestamptz          default current_timestamp not null,
    created_by  uuid,
    updated_by  uuid,

    constraint trip_fk
        foreign key (trip_id) references public.trip(id)
        on update cascade on delete restrict,
    constraint currency_fk
        foreign key (currency_id) references public.currency(id)
        on update cascade on delete restrict,
    constraint country_fk
        foreign key (country_id) references public.country(id)
        on update cascade on delete restrict,
    constraint amount_positive
            check ( amount >= 0 )
);

------------------------------------------------------------------
------------------------------------------------------------------

create table if not exists public.proof
(
    id      uuid    default uuid_generate_v4() not null primary key,
    trip_id        uuid not null,
    file_id        uuid not null,
    is_locked      boolean  default false,
    created_at  timestamptz          default current_timestamp not null,
    updated_at  timestamptz          default current_timestamp not null,
    created_by  uuid,
    updated_by  uuid,

    constraint trip_fk
        foreign key (trip_id) references public.trip(id)
        on update cascade on delete restrict,
    constraint file_fk
        foreign key (file_id) references public.file(id)
        on update cascade on delete restrict
);

------------------------------------------------------------------
------------------------------------------------------------------

create table if not exists public.validation
(
    id      uuid    default uuid_generate_v4() not null primary key,
    transaction_id        uuid,
    proof_id              uuid,
    created_at  timestamptz          default current_timestamp not null,
    updated_at  timestamptz          default current_timestamp not null,
    created_by  uuid,
    updated_by  uuid,

    constraint transaction_fk
        foreign key (transaction_id) references public.transaction
        on update cascade on delete set null,
    constraint proof_fk
        foreign key (proof_id) references public.proof
        on update cascade on delete set null
);

------------------------------------------------------------------
------------------------------------------------------------------

create table if not exists public.alert_template
(
    id      uuid    default uuid_generate_v4() not null primary key,
    name        varchar(50),
    description text,
    type        alert_type not null,
    variables jsonb,  
    content     text,
    status boolean default true not null,
    created_at  timestamptz          default current_timestamp not null,
    updated_at  timestamptz          default current_timestamp not null,
    created_by  uuid,
    updated_by  uuid
);

------------------------------------------------------------------
------------------------------------------------------------------

create table if not exists public.rule
(
    id      uuid    default uuid_generate_v4() not null primary key,
    name        varchar(30)                                         not null,
    validity_time bank_validity_time                                not null,
    start_date    date,
    end_date      date,
    target        bank_rule_target                                  not null,
    created_at  timestamptz          default current_timestamp not null,
    updated_at  timestamptz          default current_timestamp not null,
    created_by  uuid,
    updated_by  uuid
);

------------------------------------------------------------------
------------------------------------------------------------------

create table if not exists public.rule_condition
(
    id      uuid    default uuid_generate_v4() not null primary key,
    rule_id      uuid,
    criteria         varchar(30)                                          not null,
    operator         bank_condition_operator                         not null,
    value            varchar,
    to_string        varchar,
    created_at  timestamptz          default current_timestamp not null,
    updated_at  timestamptz          default current_timestamp not null,
    created_by  uuid,
    updated_by  uuid,

    constraint rule_fk
        foreign key (rule_id) references public.rule(id)
        on update cascade on delete cascade
);

------------------------------------------------------------------
------------------------------------------------------------------

create table if not exists public.alert
(
    id      uuid    default uuid_generate_v4() not null primary key,
    trip_id     uuid                  not null,
    alert_template_id     uuid not null,
    rule_id     uuid,
    directus_notifications_id  integer,
    notification_read boolean default false not null,
    created_at  timestamptz          default current_timestamp not null,
    updated_at  timestamptz          default current_timestamp not null,
    created_by  uuid,
    updated_by  uuid,

    constraint trip_fk
        foreign key (trip_id) references public.trip(id)
        on update cascade on delete restrict,
    constraint alert_template_fk
        foreign key (alert_template_id) references public.alert_template(id)
        on update cascade on delete restrict,
    constraint rule_fk
        foreign key (rule_id) references public.rule
        on update cascade on delete restrict
);

------------------------------------------------------------------
------------------------------------------------------------------

create table if not exists public.alert_recipient
(
    id      uuid    default uuid_generate_v4() not null primary key,
    alert_id    uuid          not null,
    user_id     uuid,
    recipient_email varchar(100) not null,
    sent_at timestamptz,
    status alert_status default 'pending',
    error_message text, 
    created_at  timestamptz          default current_timestamp not null,
    updated_at  timestamptz          default current_timestamp not null,
    created_by  uuid,
    updated_by  uuid,

    constraint alert_fk
        foreign key (alert_id) references public.alert(id)
        on update cascade on delete restrict,    
    constraint valid_email
        check ( recipient_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' )
);

------------------------------------------------------------------
------------------------------------------------------------------

create table if not exists public.alert_role (
    alert_id   uuid    default uuid_generate_v4() not null  primary key ,
    role_id uuid not null,
    constraint alert_fk
        foreign key (alert_id) references public.alert(id)
        on update cascade on delete restrict
);

------------------------------------------------------------------
------------------------------------------------------------------

create table if not exists public.alert_user (
    alert_id   uuid    default uuid_generate_v4() not null  primary key ,
    user_id uuid not null,
    constraint alert_fk
        foreign key (alert_id) references public.alert(id)
        on update cascade on delete restrict
);

------------------------------------------------------------------
------------------------------------------------------------------

create table if not exists public.alert_exclusions (
    alert_id   uuid    default uuid_generate_v4() not null  primary key ,
    user_id uuid not null,
    constraint alert_fk
        foreign key (alert_id) references public.alert(id)
        on update cascade on delete restrict
);

------------------------------------------------------------------
------------------------------------------------------------------
create table if not exists public.transaction_beta
(
    id      uuid    default uuid_generate_v4() not null primary key,
    amount         numeric,
    country_code   varchar(3),
    serial_number varchar(50),
    transaction_ref varchar(50),
    transaction_date date not null,
    branch_code varchar(20),
    memo varchar,
    transaction_type boolean default true, -- if true, transaction outside of CEMAC else online
    customer_type varchar(50),
    first_name varchar(50),
    last_name varchar(50),
    email varchar(100),
    phone varchar(20),
    currency varchar,
    card_type varchar(20),
    card_number varchar(30),
    status boolean default false not null,
    message_error text,
    created_at  timestamptz          default current_timestamp not null,
    updated_at  timestamptz          default current_timestamp not null,
    created_by  uuid,
    updated_by  uuid,

    constraint valid_phone
        check ( phone ~ '^[0-9]{10,20}$' ),
    constraint valid_email
        check ( email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' ),
    constraint amount_positive
            check ( amount >= 0 )
);

------------------------------------------------------------------
------------------------------------------------------------------
drop table if exists public.transaction_bank cascade;
create table if not exists public.transaction_bank
(
    id      uuid    default uuid_generate_v4() not null primary key,
    amount         varchar, -- Montant de la transaction
    country_code   varchar, -- Pays d'émission de la transaction    
    serial_number varchar, -- Numéro unique du client
    account_number varchar, -- Numéro de compte du client
    transaction_date varchar, -- Date d'émission de la transaction
    transaction_ref varchar,  -- Référence de la transaction
    memo varchar,             -- Descriptif sur l'objet de la transaction
    transaction_type varchar, -- Type de transaction, est-elle en ligne ou hors ligne?
    customer_type varchar(50),-- Type de client
    first_name varchar(50),   -- Prénom du client
    last_name varchar(50),    -- Nom du client
    email varchar(100),       -- Email du client
    phone varchar(20),        -- Numéro de téléphone du client
    currency varchar,         -- Devise de la transaction
    card_type varchar(20),    -- Type de carte de transaction
    card_number varchar(30),  -- Numéro de carte bancaire
    branch_code varchar(20),  -- Code du guichet de la banque
    created_at  timestamptz          default current_timestamp not null,
    updated_at  timestamptz          default current_timestamp not null,
    created_by  uuid,
    updated_by  uuid
);
