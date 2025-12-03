-------------------------------------------------------
-- ÜNİVERSİTE ÖĞRENCİ İŞLERİ SİSTEMİ VERİTABANI PROJESİ
-- Hazırlayan: Cem Boğazlıyanlıoğlu
-------------------------------------------------------


-- Mevcut tabloları temizle (Test amaçlı, üretimde kullanılmaz)
-- CASCADE: İlişkili verileri de siler (örn. bir öğrenci silinince notları da silinir).
DROP TABLE IF EXISTS grades CASCADE;
DROP TABLE IF EXISTS enrollments CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS courses CASCADE;
DROP TABLE IF EXISTS instructors CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS faculties CASCADE;

-- 1. Fakülteler
CREATE TABLE faculties (
    faculty_id SERIAL PRIMARY KEY,
    faculty_name VARCHAR(100) UNIQUE NOT NULL
);

-- 2. Bölümler (Fakültelere bağlı)
CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(100) UNIQUE NOT NULL,
    faculty_id INTEGER REFERENCES faculties(faculty_id) ON DELETE CASCADE
); 
-- FK: Bir bölümün hangi fakülteye ait olduğunu belirtir.
-- ON DELETE CASCADE: Fakülte silinirse, o fakülteye bağlı bölümler de silinir.


-- 3. Öğretim Görevlileri (Bölümlere bağlı)
CREATE TABLE instructors (
    instructor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id) ON DELETE RESTRICT
);

-- 4. Dersler (Bölümlere bağlı)
CREATE TABLE courses (
    course_id VARCHAR(10) PRIMARY KEY, -- Örn: CSE101
    course_name VARCHAR(100) NOT NULL,
    credits NUMERIC(2, 0) NOT NULL CHECK (credits > 0), -- Kredi 1 veya daha fazla olmalı.
    max_capacity INTEGER NOT NULL CHECK (max_capacity > 0), -- Kontenjan pozitif olmalı.
    instructor_id INTEGER REFERENCES instructors(instructor_id) ON DELETE SET NULL,
    -- FK: Dersi veren öğretim görevlisi. Görevli ayrılırsa ID NULL olur.
    dept_id INTEGER REFERENCES departments(dept_id) ON DELETE RESTRICT
);

-- 5. Öğrenciler (Bölümlere bağlı)
CREATE TABLE students (
    student_id BIGINT PRIMARY KEY, -- Örn: 202300001 Öğrenci numarası (Büyük sayı olabilir)
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    enrollment_year INTEGER NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id) ON DELETE RESTRICT, 
    current_gpa NUMERIC(3, 2) DEFAULT 0.00 -- Genel not ortalaması (Fonksiyon ile güncellenir)
);

-- 6. Ders Kayıtları (Hangi öğrenci hangi derse kayıtlı - Many-to-Many ilişkisini sağlar)
CREATE TABLE enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id BIGINT REFERENCES students(student_id) ON DELETE CASCADE, -- ÖĞRENCİ SİLİNİRSE KAYITLAR SİLİNİR
    course_id VARCHAR(10) REFERENCES courses(course_id) ON DELETE CASCADE,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    semester VARCHAR(10) NOT NULL, -- Örn: 'Güz 2024'
    UNIQUE (student_id, course_id) -- UNIQUE: Bir öğrencinin aynı derse birden fazla kez kayıt olmasını engeller.
);

-- 7. Notlar (Öğrencinin dersten aldığı not)
CREATE TABLE grades (
    grade_id SERIAL PRIMARY KEY,
    -- UNIQUE kısıtlaması, bir derse (enrollment) sadece bir not girişi yapılmasını sağlar.
    enrollment_id INTEGER REFERENCES enrollments(enrollment_id) ON DELETE CASCADE UNIQUE,
    midterm_grade NUMERIC(3, 0),
    final_grade NUMERIC(3, 0),
    letter_grade VARCHAR(2), -- Trigger ile otomatik hesaplanır. -- AA, BB, FF gibi
    grade_point NUMERIC(3, 2) -- Trigger ile otomatik hesaplanır (4.00, 3.50 vb.)
);


-- 1. FAKÜLTELER
INSERT INTO faculties (faculty_name) VALUES 
('Mühendislik Fakültesi'), -- ID: 1
('İktisadi ve İdari Bilimler Fakültesi'), -- ID: 2
('Fen-Edebiyat Fakültesi'); -- ID: 3

-- 2. BÖLÜMLER
INSERT INTO departments (dept_name, faculty_id) VALUES 
('Bilgisayar Mühendisliği', 1), -- ID: 1
('Elektrik-Elektronik Mühendisliği', 1), -- ID: 2
('Endüstri Mühendisliği', 1), -- ID: 3
('İşletme', 2), -- ID: 4
('İktisat', 2), -- ID: 5
('Matematik', 3); -- ID: 6

-- 3. ÖĞRETİM GÖREVLİLERİ
INSERT INTO instructors (first_name, last_name, dept_id) VALUES 
('Ayşe', 'Yılmaz', 1), -- ID: 1 (CSE)
('Mehmet', 'Kaya', 1), -- ID: 2 (CSE)
('Fatma', 'Demir', 2), -- ID: 3 (EEE)
('Ali', 'Öztürk', 3), -- ID: 4 (IE)
('Deniz', 'Çelik', 4), -- ID: 5 (BUS)
('Hakan', 'Şahin', 4), -- ID: 6 (BUS)
('Seda', 'Akın', 5), -- ID: 7 (ECON)
('Murat', 'Güler', 6), -- ID: 8 (MATH)
('Elif', 'Arslan', 1), -- ID: 9 (CSE)
('Can', 'Kurt', 2); -- ID: 10 (EEE)

-- 4. DERSLER
INSERT INTO courses (course_id, course_name, credits, max_capacity, instructor_id, dept_id) VALUES 
('CSE101', 'Giriş Programlama', 4, 3, 2, 1),    -- Düşük Kontenjan (Kontenjan test için Trigger için)
('CSE204', 'Veritabanı Sistemleri', 3, 25, 1, 1), 
('CSE305', 'Algoritma Analizi', 5, 20, 9, 1), 
('EEE201', 'Devre Teorisi', 4, 30, 3, 2),
('IE301', 'Yöneylem Araştırması', 4, 20, 4, 3), 
('BUS101', 'Genel İşletme', 3, 40, 5, 4), 
('ECON201', 'Mikro İktisat', 4, 35, 7, 5),
('MATH101', 'Matematik I', 5, 50, 8, 6),
('CSE499', 'Büyük Veri', 4, 10, 9, 1);

-- 5. ÖĞRENCİLER (Farklı GPA durumlarını test etmek için 15 adet)
INSERT INTO students (student_id, first_name, last_name, enrollment_year, dept_id, current_gpa) VALUES 
(202300001, 'Buse', 'Aksoy', 2023, 1, 3.85), -- Yüksek Onur (Takdir)
(202200002, 'Kerem', 'Polat', 2022, 1, 3.10), -- Onur (Teşekkür)
(202100003, 'Gizem', 'Deniz', 2021, 1, 1.95), -- Şartlı (Düşük)
(202000004, 'Emre', 'Kara', 2020, 1, 2.50),  -- Normal
(202300005, 'Mert', 'Yıldız', 2023, 2, 2.90),
(202200006, 'Esra', 'Can', 2022, 2, 3.75),
(202100007, 'Koray', 'Aydın', 2021, 3, 2.15),
(202300008, 'Melisa', 'Toprak', 2023, 4, 3.25),
(202200009, 'Hasan', 'Uslu', 2022, 4, 1.80), -- Şartlı
(202100010, 'Zeynep', 'Er', 2021, 5, 2.40),
(202000011, 'Okan', 'Güneş', 2020, 5, 3.40), -- Teşekkür
(202300012, 'Selin', 'Koç', 2023, 6, 2.75),
(202300013, 'Alp', 'Tekin', 2023, 1, 3.00), -- Kontenjan testi için
(202300014, 'İrem', 'Ateş', 2023, 1, 2.90), -- Kontenjan testi için
(202300015, 'Doğa', 'Su', 2023, 1, 3.05); -- Kontenjan testi için

-- 6. DERS KAYITLARI (CSE101'in kontenjanı 3'tür, 4. kayıt trigger'ı test eder.)
INSERT INTO enrollments (student_id, course_id, semester) VALUES 
(202300001, 'CSE101', 'Güz 2024'), -- ID: 1
(202300001, 'MATH101', 'Güz 2024'), -- ID: 2
(202200002, 'CSE101', 'Güz 2024'), -- ID: 3
(202100003, 'CSE101', 'Güz 2024'), -- ID: 4 (Kontenjan Dolu)

(202300001, 'IE301', 'Bahar 2024'), -- ID: 5 (Dönem GPA testi için)
(202300001, 'BUS101', 'Bahar 2024'), -- ID: 6 (Dönem GPA testi için)
(202200002, 'CSE204', 'Güz 2024'), -- ID: 7
(202300008, 'BUS101', 'Güz 2024'), -- ID: 8
(202200009, 'BUS101', 'Güz 2024'), -- ID: 9
(202300013, 'CSE204', 'Güz 2024'), -- ID: 10
(202300014, 'CSE204', 'Güz 2024'), -- ID: 11
(202300015, 'CSE204', 'Güz 2024'); -- ID: 12

-- 7. NOTLAR (INSERT INTO işlemi 4.2'deki trigger'ı tetikleyecektir.)
INSERT INTO grades (enrollment_id, midterm_grade, final_grade) VALUES 
(1, 95, 90), -- Buse, CSE101 (Yüksek Ağırlık)
(2, 88, 85), -- Buse, MATH101
(3, 75, 70), -- Kerem, CSE101
(4, 40, 50), -- Gizem, CSE101 (F Kalacak)
(5, 75, 80), -- Buse, IE301 (Bahar)
(6, 60, 65), -- Buse, BUS101 (Bahar)
(7, 78, 82), -- Kerem, CSE204
(8, 90, 95), -- Melisa, BUS101
(9, 45, 48), -- Hasan, BUS101 (F Kalacak)
(10, 80, 85), -- Alp, CSE204
(11, 70, 75), -- İrem, CSE204
(12, 65, 70); -- Doğa, CSE204

----------------------------------------------------------------------
-- 3. FONKSİYONLAR 
----------------------------------------------------------------------

-- 3.1. calculate_gpa(student_id): Öğrencinin genel not ortalamasını hesaplar ve students tablosunu günceller.
-- Formül: (Ders Puanı * Kredi) Toplamı / Kredi Toplamı
CREATE OR REPLACE FUNCTION calculate_gpa(p_student_id BIGINT)
RETURNS NUMERIC AS $$
DECLARE
    v_total_points NUMERIC := 0.0;
    v_total_credits NUMERIC := 0.0;
    v_gpa NUMERIC := 0.0;
BEGIN
-- Öğrencinin aldığı derslerin toplam puanını ve toplam kredisini hesapla
    SELECT 
        COALESCE(SUM(g.grade_point * c.credits), 0), 
        COALESCE(SUM(c.credits), 0)
    INTO 
        v_total_points, v_total_credits
    FROM 
        grades g
    JOIN 
        enrollments e ON e.enrollment_id = g.enrollment_id
    JOIN 
        courses c ON c.course_id = e.course_id
    WHERE 
        e.student_id = p_student_id AND g.grade_point IS NOT NULL;

    IF v_total_credits > 0 THEN
        v_gpa := v_total_points / v_total_credits;
    ELSE
        v_gpa := 0.0;
    END IF;

    -- Öğrenci tablosundaki current_gpa alanını günceller
    UPDATE students SET current_gpa = ROUND(v_gpa, 2) WHERE student_id = p_student_id;
    
    RETURN ROUND(v_gpa, 2);
END;
$$ LANGUAGE plpgsql;

-- 3.2. course_capacity_check(course_id): Dersin doluluk oranını (% olarak) hesaplar.
CREATE OR REPLACE FUNCTION course_capacity_check(p_course_id VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
    v_enrolled_count INTEGER;
    v_max_capacity INTEGER;
BEGIN
-- Kayıtlı öğrenci sayısını bul
    SELECT COUNT(*) INTO v_enrolled_count FROM enrollments WHERE course_id = p_course_id;
-- Dersin maksimum kapasitesini bul
    SELECT max_capacity INTO v_max_capacity FROM courses WHERE course_id = p_course_id;

    IF v_max_capacity IS NULL OR v_max_capacity = 0 THEN
        RETURN 0.0; -- Kontenjan bilgisi yoksa 0 döndür
    END IF;
-- Doluluk Yüzdesi = (Kayıtlı Sayısı * 100) / Maksimum Kapasite
    RETURN ROUND((v_enrolled_count * 100.0) / v_max_capacity, 2);
END;
$$ LANGUAGE plpgsql;

-- 3.3. student_academic_status(gpa): Akademik durumu belirleyen
-- Akademik durumu (Takdir/Teşekkür/Normal/Şartlı) belirleyen fonksiyon.
CREATE OR REPLACE FUNCTION student_academic_status(p_gpa NUMERIC)
RETURNS VARCHAR AS $$
BEGIN
    IF p_gpa >= 3.50 THEN
        RETURN 'Yüksek Onur (Takdir)';
    ELSIF p_gpa >= 3.00 AND p_gpa < 3.50 THEN
        RETURN 'Onur (Teşekkür)';
    ELSIF p_gpa >= 2.00 AND p_gpa < 3.00 THEN
        RETURN 'Normal';
    ELSE 
        RETURN 'Şartlı (Sınamalı)';
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE; -- Sabit girdi için IMMUTABLE

-- 3.4. Fonksiyon Test Sorguları
-- Buse'nin GPA'sını yeniden hesapla ve öğrencideki current_gpa alanını kontrol et
SELECT calculate_gpa(202300001) AS buse_gpa; -- Buse'nin yeni GPA'sını hesapla
-- CSE101'in doluluk oranını kontrol et (Kontenjan: 3, Kayıt: 4. Bu fonksiyon, trigger sonrası 4/3 * 100 = %133.33 döndürmeli)
SELECT calculate_gpa(202100003) AS gizem_gpa; -- Gizem'in yeni GPA'sını hesapla

-- Gizem'in (1.95) akademik durumunu kontrol e
SELECT course_capacity_check('CSE101') AS cse101_doluluk; -- %100'ü geçmeli
SELECT course_capacity_check('CSE204') AS cse204_doluluk;

SELECT student_academic_status(3.85) AS durum_takdir;
SELECT student_academic_status(1.99) AS durum_sartli;

----------------------------------------------------------------------
-- 4. TRIGGERLAR 
----------------------------------------------------------------------

-- 4.1. Ders Kontenjan Kontrolü Trigger'ı (Ders kaydı yapılırken kontenjan kontrolü)
-- Ders kaydı (INSERT) yapılmadan ÖNCE çalışır.
CREATE OR REPLACE FUNCTION trg_check_enrollment_capacity_func()
RETURNS TRIGGER AS $$
DECLARE
    v_current_enrollment INTEGER;
    v_max_capacity INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_current_enrollment 
    FROM enrollments 
    WHERE course_id = NEW.course_id;

    SELECT max_capacity INTO v_max_capacity 
    FROM courses 
    WHERE course_id = NEW.course_id;

    -- Kontenjan 3, zaten 3 kişi kayıtlı. 4. kişi gelince hata fırlatılacak.
	-- Kontenjan aşıldıysa HATA fırlat ve işlemi geri al
    IF v_current_enrollment >= v_max_capacity THEN
        RAISE EXCEPTION 'Dersin kontenjanı dolmuştur (Max: %)', v_max_capacity;
    END IF;

    RETURN NEW; -- İşleme devam et
END;
$$ LANGUAGE plpgsql;

-- Kontenjan Kontrolü Trigger Tanımlaması
CREATE TRIGGER trg_check_enrollment_capacity
BEFORE INSERT ON enrollments
FOR EACH ROW
EXECUTE FUNCTION trg_check_enrollment_capacity_func();


-- 4.2. Harf Notunu Otomatik Hesaplayan Trigger (Not girildiğinde harf notunu otomatik hesaplar)
-- Notlar (midterm/final) girilmeden ÖNCE çalışır ve letter_grade/grade_point alanlarını doldurur.
CREATE OR REPLACE FUNCTION trg_calculate_letter_grade_func()
RETURNS TRIGGER AS $$
DECLARE
    v_raw_grade NUMERIC;
BEGIN
    -- Vize %40, Final %60 kabul edelim
	-- Ortalamayı hesapla (Vize %40, Final %60)
    v_raw_grade := (NEW.midterm_grade * 0.4) + (NEW.final_grade * 0.6);

    -- Harf Notu ve Puanı Hesaplama 
    IF v_raw_grade >= 90 THEN
        NEW.letter_grade := 'AA'; NEW.grade_point := 4.00;
    ELSIF v_raw_grade >= 85 THEN
        NEW.letter_grade := 'BA'; NEW.grade_point := 3.50;
    ELSIF v_raw_grade >= 80 THEN
        NEW.letter_grade := 'BB'; NEW.grade_point := 3.00;
    ELSIF v_raw_grade >= 70 THEN
        NEW.letter_grade := 'CB'; NEW.grade_point := 2.50;
    ELSIF v_raw_grade >= 60 THEN
        NEW.letter_grade := 'CC'; NEW.grade_point := 2.00;
    ELSIF v_raw_grade >= 50 THEN
        NEW.letter_grade := 'DD'; NEW.grade_point := 1.00;
    ELSE 
        NEW.letter_grade := 'F'; NEW.grade_point := 0.00;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Harf Notu Hesaplama Trigger Tanımlaması
CREATE TRIGGER trg_auto_calculate_grade
BEFORE INSERT OR UPDATE OF midterm_grade, final_grade ON grades
FOR EACH ROW
EXECUTE FUNCTION trg_calculate_letter_grade_func();

-- 4.3. Öğrenci silindiğinde ilgili kayıtları da silen trigger
-- BU İŞLEM TABLO OLUŞTURMA AŞAMASINDA 'ON DELETE CASCADE' İLE ÇÖZÜLMÜŞTÜR.
-- (students -> enrollments -> grades) zinciri otomatik çalışır.

-- 4.4. Trigger Test Sorguları

-- Test 1: Kontenjan Kontrolü (Başarısız Olmalı)
-- CSE101'in kontenjanı 3, 4 kayıt zaten var (ID 1, 3, 4). Bu 5. kayıt denemesi hata vermelidir.
-- CALL sp_enroll_course(202300012, 'CSE101', 'Güz 2024'); -- Bunu sp testi ile yapacağız.
-- sp_enroll_course ile daha temiz test edilebilir.


-- Test 2: Harf Notu Otomatik Hesaplama (midterm: 50, final: 50 -> Ortalama 50 -> DD)
INSERT INTO enrollments (student_id, course_id, semester) VALUES (202000004, 'MATH101', 'Güz 2024'); -- ID: 13
INSERT INTO grades (enrollment_id, midterm_grade, final_grade) VALUES (13, 50, 50); 
SELECT letter_grade FROM grades WHERE enrollment_id = 13; -- Sonucu kontrol et

-- Test 3: Cascade Delete (202200002 ID'li öğrencinin 3 kaydı var (ID 3, 7, 13))
DELETE FROM students WHERE student_id = 202200002;
SELECT COUNT(*) FROM enrollments WHERE student_id = 202200002; -- Sonucun 0 olması beklenir

---

----------------------------------------------------------------------
-- 5. STORED PROCEDURE'LER (PL/pgSQL) (15 Puan)
----------------------------------------------------------------------

-- 5.1. sp_enroll_course(): Ders kaydı yapma (Kontenjan kontrolü trigger ile sağlanır)
CREATE OR REPLACE PROCEDURE sp_enroll_course(
    p_student_id BIGINT, 
    p_course_id VARCHAR, 
    p_semester VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    -- INSERT INTO, 4.1'deki Kontenjan Kontrolü Trigger'ını otomatik tetikleyecektir.
    INSERT INTO enrollments (student_id, course_id, semester)
    VALUES (p_student_id, p_course_id, p_semester);
    
    COMMIT;-- İşlemi onayla
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Öğrenci % dersine zaten kayıtlı.', p_course_id;
    -- Kontenjan doluluğu trigger tarafından yakalanır ve kendisi hata fırlatır.
    WHEN OTHERS THEN
    -- Kontenjan hatası dahil, diğer hatalar bu blokta yakalanır.
         RAISE EXCEPTION 'Ders kaydı yapılamadı. Hata: %', SQLERRM;
END;
$$;

-- 5.2. sp_calculate_semester_gpa(): Dönem not ortalaması hesaplama
CREATE OR REPLACE PROCEDURE sp_calculate_semester_gpa(
    p_student_id BIGINT, 
    p_semester VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total_points NUMERIC := 0.0;
    v_total_credits NUMERIC := 0.0;
    v_semester_gpa NUMERIC := 0.0;
BEGIN
-- Belirtilen dönemdeki puan ve kredi toplamını hesapla
    SELECT 
        COALESCE(SUM(g.grade_point * c.credits), 0), 
        COALESCE(SUM(c.credits), 0)
    INTO 
        v_total_points, v_total_credits
    FROM 
        grades g
    JOIN 
        enrollments e ON e.enrollment_id = g.enrollment_id
    JOIN 
        courses c ON c.course_id = e.course_id
    WHERE 
        e.student_id = p_student_id 
        AND e.semester = p_semester 
        AND g.grade_point IS NOT NULL;

    IF v_total_credits > 0 THEN
        v_semester_gpa := ROUND(v_total_points / v_total_credits, 2);
    ELSE
        v_semester_gpa := 0.0;
    END IF;
    -- Sonucu kullanıcıya NOTICE olarak bildir.
    RAISE NOTICE 'Öğrenci ID: %, Dönem: %, Dönem GPA: %', p_student_id, p_semester, v_semester_gpa;
END;
$$;

-- 5.3. Procedure Test Sorguları
-- Test 1: sp_enroll_course - Kontenjan Dolu Ders Kaydı (Hata vermesi beklenir)
-- Öğrenci 202300012, CSE101'e kayıt denemesi yapıyor. Kontenjan 3 ve dolu.
CALL sp_enroll_course(202300012, 'CSE101', 'Güz 2024'); 

-- Test 2: sp_enroll_course - Başarılı Ders Kaydı (CSE499 kontenjanı 10)
CALL sp_enroll_course(202300012, 'CSE499', 'Güz 2024'); 

-- Test 3: sp_calculate_semester_gpa (Buse'nin Bahar 2024 GPA'sını hesapla - ID: 5 ve 6 numaralı kayıtlar)
CALL sp_calculate_semester_gpa(202300001, 'Bahar 2024'); 

----------------------------------------------------------------------
-- 6. VIEW'LAR
----------------------------------------------------------------------

-- 6.1. Bölümlere göre öğrenci sayıları ve ortalama GPA'lar
CREATE OR REPLACE VIEW view_department_stats AS
SELECT
    d.dept_name,
    f.faculty_name,
    COUNT(s.student_id) AS student_count,
    ROUND(AVG(s.current_gpa), 2) AS average_gpa
FROM
    departments d
JOIN
    faculties f ON f.faculty_id = d.faculty_id
LEFT JOIN
    students s ON s.dept_id = d.dept_id
GROUP BY
    d.dept_name, f.faculty_name;

-- 6.2. Öğretim görevlilerinin ders yükleri (Kaç ders verdikleri ve toplam kredi yükleri)
CREATE OR REPLACE VIEW view_instructor_workload AS
SELECT
    i.first_name || ' ' || i.last_name AS instructor_full_name,
    d.dept_name,
    COUNT(c.course_id) AS total_courses_taught,
    COALESCE(SUM(c.credits), 0) AS total_credit_load
FROM
    instructors i
LEFT JOIN
    courses c ON c.instructor_id = i.instructor_id
JOIN
    departments d ON d.dept_id = i.dept_id
GROUP BY
    i.instructor_id, i.first_name, i.last_name, d.dept_name
ORDER BY
    total_courses_taught DESC;

-- 6.3. View Test Sorguları
SELECT * FROM view_department_stats;
SELECT * FROM view_instructor_workload;

----------------------------------------------------------------------
-- 7. KOMPLEKS SORGULAR 
----------------------------------------------------------------------

-- 7.1. Fakültelere göre en başarılı öğrenciler (Window Function/JOIN)
WITH RankedStudents AS (
    SELECT
        s.student_id,
        s.first_name,
        s.last_name,
        s.current_gpa,
        f.faculty_name,
        -- Her fakülte içinde GPA'ya göre sıralama yapar
        ROW_NUMBER() OVER (PARTITION BY f.faculty_id ORDER BY s.current_gpa DESC) as rn
    FROM
        students s
    JOIN
        departments d ON d.dept_id = s.dept_id
    JOIN
        faculties f ON f.faculty_id = d.faculty_id
)
SELECT
    faculty_name,
    first_name,
    last_name,
    current_gpa
FROM
    RankedStudents
    -- Sadece 1. sıradakileri al
WHERE
    rn = 1
ORDER BY current_gpa DESC;


-- 7.2. En çok tercih edilen dersler (GROUP BY + HAVING)
-- En az 3 öğrenci tarafından kayıt edilen dersleri listele
SELECT
    c.course_id,
    c.course_name,
    COUNT(e.enrollment_id) AS enrollment_count
FROM
    courses c
JOIN
    enrollments e ON e.course_id = c.course_id
GROUP BY
    c.course_id, c.course_name
    -- Kayıt sayısı 3'ten büyük veya eşit olanları filtrele
HAVING
    COUNT(e.enrollment_id) >= 3 
ORDER BY
    enrollment_count DESC;


-- 7.3. Subquery ile: GPA ortalamasının üstünde olan öğrenciler
SELECT
    student_id,
    first_name,
    last_name,
    current_gpa
FROM
    students
where
-- Öğrenci GPA'sının, tüm öğrencilerin ortalama GPA'sından yüksek olup olmadığını kontrol et
    current_gpa > (
        -- Subquery: Tüm öğrencilerin genel GPA ortalaması
        SELECT 
            AVG(current_gpa) 
        FROM 
            students
    )
ORDER BY
    current_gpa DESC;
