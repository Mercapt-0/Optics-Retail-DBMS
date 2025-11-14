-- ===== BASE TABLES (no dependencies) =====
CREATE TABLE Fall25_S003_T8_PERSON (
    person_id NUMBER(10) PRIMARY KEY,
    f_name VARCHAR2(100),
    l_name VARCHAR2(100),
    dob DATE,
    gender VARCHAR2(10),
    street VARCHAR2(255),
    city VARCHAR2(100),
    state VARCHAR2(100),
    zip VARCHAR2(20)
);

CREATE TABLE Fall25_S003_T8_SUPPLIER (
    supplier_id NUMBER(10) PRIMARY KEY,
    name VARCHAR2(255),
    email VARCHAR2(255),
    phone VARCHAR2(20)
);

CREATE TABLE Fall25_S003_T8_PRODUCT (
    product_id NUMBER(10) PRIMARY KEY,
    model VARCHAR2(100),
    brand VARCHAR2(100),
    size_mm VARCHAR2(50),
    price NUMBER(10, 2),
    category VARCHAR2(100),
    color VARCHAR2(50),
    material VARCHAR2(100),
    lenstype VARCHAR2(100)
);

CREATE TABLE Fall25_S003_T8_WARRANTY (
    warr_no VARCHAR2(100) PRIMARY KEY,
    period VARCHAR2(100),
    status VARCHAR2(50),
    coverage_details CLOB,
    refund_amt NUMBER(10, 2)
);

-- ===== DEPENDENT ON PERSON =====
CREATE TABLE Fall25_S003_T8_PERSON_CONTACT (
    person_id NUMBER(10),
    phone VARCHAR2(20),
    email VARCHAR2(255),
    PRIMARY KEY (person_id, phone),
    FOREIGN KEY (person_id) REFERENCES Fall25_S003_T8_PERSON(person_id) ON DELETE CASCADE
);

CREATE TABLE Fall25_S003_T8_EMPLOYEE (
    emp_person_id NUMBER(10) PRIMARY KEY,
    emp_id VARCHAR2(50),
    position VARCHAR2(100),
    salary NUMBER(10, 2),
    hire_date DATE,
    sales_target NUMBER(10, 2),
    supervisor_emp_person_id NUMBER(10),
    FOREIGN KEY (emp_person_id) REFERENCES Fall25_S003_T8_PERSON(person_id) ON DELETE CASCADE,
    FOREIGN KEY (supervisor_emp_person_id) REFERENCES Fall25_S003_T8_EMPLOYEE(emp_person_id) ON DELETE SET NULL
);

CREATE TABLE Fall25_S003_T8_CUSTOMER (
    cust_person_id NUMBER(10) PRIMARY KEY,
    cust_id VARCHAR2(50),
    FOREIGN KEY (cust_person_id) REFERENCES Fall25_S003_T8_PERSON(person_id) ON DELETE CASCADE
);

-- ===== DEPENDENT ON EMPLOYEE =====
CREATE TABLE Fall25_S003_T8_OPTOMETRIST (
    opti_emp_person_id NUMBER(10) PRIMARY KEY,
    opt_emp_id VARCHAR2(50),
    opt_id VARCHAR2(50),
    lisence_no VARCHAR2(100),
    FOREIGN KEY (opti_emp_person_id) REFERENCES Fall25_S003_T8_EMPLOYEE(emp_person_id) ON DELETE CASCADE
);

-- ===== JUNCTION TABLES =====
CREATE TABLE Fall25_S003_T8_SELLS (
    emp_person_id NUMBER(10),
    product_id NUMBER(10),
    PRIMARY KEY (emp_person_id, product_id),
    FOREIGN KEY (emp_person_id) REFERENCES Fall25_S003_T8_EMPLOYEE(emp_person_id),
    FOREIGN KEY (product_id) REFERENCES Fall25_S003_T8_PRODUCT(product_id)
);

CREATE TABLE Fall25_S003_T8_BUYS (
    cust_person_id NUMBER(10),
    product_id NUMBER(10),
    PRIMARY KEY (cust_person_id, product_id),
    FOREIGN KEY (cust_person_id) REFERENCES Fall25_S003_T8_CUSTOMER(cust_person_id),
    FOREIGN KEY (product_id) REFERENCES Fall25_S003_T8_PRODUCT(product_id)
);

CREATE TABLE Fall25_S003_T8_SUPPLIES (
    supplier_id NUMBER(10),
    product_id NUMBER(10),
    PRIMARY KEY (supplier_id, product_id),
    FOREIGN KEY (supplier_id) REFERENCES Fall25_S003_T8_SUPPLIER(supplier_id),
    FOREIGN KEY (product_id) REFERENCES Fall25_S003_T8_PRODUCT(product_id)
);

-- ===== DETAIL TABLES =====
CREATE TABLE Fall25_S003_T8_SELLS_details (
    emp_person_id NUMBER(10),
    product_id NUMBER(10),
    date_sold DATE,
    quantity NUMBER(5),
    PRIMARY KEY (emp_person_id, product_id, date_sold),
    FOREIGN KEY (emp_person_id, product_id) REFERENCES Fall25_S003_T8_SELLS(emp_person_id, product_id) ON DELETE CASCADE
);

CREATE TABLE Fall25_S003_T8_BUYS_details (
    cust_person_id NUMBER(10),
    product_id NUMBER(10),
    buy_date DATE,
    warr_no VARCHAR2(100) NULL,
    payment_method VARCHAR2(50),
    total_sale_value NUMBER(10, 2),
    quantity NUMBER(5),
    PRIMARY KEY (cust_person_id, product_id, buy_date),
    FOREIGN KEY (cust_person_id, product_id) REFERENCES Fall25_S003_T8_BUYS(cust_person_id, product_id) ON DELETE CASCADE,
    FOREIGN KEY (warr_no) REFERENCES Fall25_S003_T8_WARRANTY(warr_no) ON DELETE SET NULL
);

CREATE TABLE Fall25_S003_T8_SUPPLIES_details (
    supplier_id NUMBER(10),
    product_id NUMBER(10),
    supply_date DATE,
    quantity NUMBER(5),
    unit_cost NUMBER(10, 2),
    PRIMARY KEY (supplier_id, product_id, supply_date),
    FOREIGN KEY (supplier_id, product_id) REFERENCES Fall25_S003_T8_SUPPLIES(supplier_id, product_id) ON DELETE CASCADE
);

CREATE TABLE Fall25_S003_T8_PRESCRIPTION (
    prescription_id NUMBER(10) PRIMARY KEY,
    opti_emp_person_id NUMBER(10),
    cust_person_id NUMBER(10),
    issue_date DATE,
    lens_type VARCHAR2(100),
    left_details VARCHAR2(100),
    right_details VARCHAR2(100),
    opt_emp_id VARCHAR2(50),
    opt_id VARCHAR2(50),
    FOREIGN KEY (opti_emp_person_id) REFERENCES Fall25_S003_T8_OPTOMETRIST(opti_emp_person_id) ON DELETE SET NULL,
    FOREIGN KEY (cust_person_id) REFERENCES Fall25_S003_T8_CUSTOMER(cust_person_id) ON DELETE CASCADE
);