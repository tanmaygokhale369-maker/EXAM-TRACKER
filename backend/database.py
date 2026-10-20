import os
import sqlite3
from datetime import date, timedelta
from werkzeug.security import generate_password_hash

DB = "exam_tracker.db"
ADMIN_EMAIL    = "admin@examtracker.com"


def get_db():
    conn = sqlite3.connect(DB)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def days_from_now(n: int) -> str:
    return (date.today() + timedelta(days=n)).isoformat()


def init_db():
    admin_password = os.environ.get("ADMIN_PASSWORD")
    if not admin_password:
        raise RuntimeError("ADMIN_PASSWORD environment variable is required")

    conn = get_db()
    c = conn.cursor()

    c.executescript("""
        CREATE TABLE IF NOT EXISTS users (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            email       TEXT UNIQUE NOT NULL,
            password    TEXT NOT NULL,
            pin         TEXT,
            fcm_token   TEXT,
            is_admin    INTEGER DEFAULT 0,
            created_at  TEXT DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS profiles (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id       INTEGER UNIQUE NOT NULL,
            full_name     TEXT NOT NULL,
            age           INTEGER,
            gender        TEXT,
            location      TEXT,
            marks_10th    REAL DEFAULT 0,
            marks_12th    REAL DEFAULT 0,
            stream        TEXT,
            qualification TEXT,
            status        TEXT DEFAULT 'Studying',
            language      TEXT DEFAULT 'en',
            caste         TEXT DEFAULT 'General'
        );
        CREATE TABLE IF NOT EXISTS exams (
            id               INTEGER PRIMARY KEY AUTOINCREMENT,
            name             TEXT NOT NULL,
            description      TEXT,
            category         TEXT,
            start_date       TEXT,
            last_date        TEXT NOT NULL,
            exam_date        TEXT,
            website          TEXT,
            min_age          INTEGER DEFAULT 0,
            max_age          INTEGER DEFAULT 99,
            streams          TEXT DEFAULT 'ALL',
            min_qual         TEXT DEFAULT '10th',
            min_10th         REAL DEFAULT 0,
            min_12th         REAL DEFAULT 0,
            fee_general      REAL DEFAULT 0,
            fee_obc          REAL DEFAULT 0,
            fee_sc           REAL DEFAULT 0,
            fee_st           REAL DEFAULT 0,
            fee_pwd          REAL DEFAULT 0,
            fee_female       REAL DEFAULT 0,
            seats            INTEGER DEFAULT 0,
            mode             TEXT DEFAULT 'Online',
            gender_allowed   TEXT DEFAULT 'ALL',
            is_active        INTEGER DEFAULT 1,
            eligibility_note TEXT,
            created_at       TEXT DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS bookmarks (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id  INTEGER NOT NULL,
            exam_id  INTEGER NOT NULL,
            UNIQUE(user_id, exam_id)
        );
        CREATE TABLE IF NOT EXISTS notifications (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id   INTEGER NOT NULL,
            exam_id   INTEGER,
            title     TEXT NOT NULL,
            body      TEXT NOT NULL,
            type      TEXT DEFAULT 'info',
            priority  TEXT DEFAULT 'low',
            is_read   INTEGER DEFAULT 0,
            sent_at   TEXT DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS user_preferences (
            user_id        INTEGER PRIMARY KEY,
            alert_urgent   INTEGER DEFAULT 1,
            alert_medium   INTEGER DEFAULT 1,
            alert_low      INTEGER DEFAULT 0,
            alert_missed   INTEGER DEFAULT 1,
            daily_summary  INTEGER DEFAULT 1,
            language       TEXT DEFAULT 'en'
        );
    """)

    c.execute("DELETE FROM exams")

    def add(name, desc, cat, s, l, e, web,
            mina, maxa, streams, qual, m10, m12,
            fg, fo, fsc, fst, fp, ff,
            seats, mode, gender="ALL", note=""):
        c.execute("""
            INSERT INTO exams
            (name,description,category,start_date,last_date,exam_date,
             website,min_age,max_age,streams,min_qual,min_10th,min_12th,
             fee_general,fee_obc,fee_sc,fee_st,fee_pwd,fee_female,
             seats,mode,gender_allowed,eligibility_note)
            VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """, (name, desc, cat,
              days_from_now(s), days_from_now(l), days_from_now(e), web,
              mina, maxa, streams, qual, m10, m12,
              fg, fo, fsc, fst, fp, ff,
              seats, mode, gender, note))
        # ══════════════════════════════════════════════════════════════
    # 1. ENGINEERING (National)
    # ══════════════════════════════════════════════════════════════
    add("JEE Main 2026 (Session 2)", "Engineering entrance for NITs, IIITs, GFTIs.", "Engineering", -5, 2, 34, "https://jeemain.nta.nic.in", 17, 25, '["PCM"]', "12th", 75.0, 75.0, 1000, 900, 500, 500, 500, 900, 150000, "Online", "ALL", "12th PCM with 75% (65% SC/ST). Max 3 attempts.")
    add("JEE Advanced 2026", "Gateway to IITs. Top 2.5 lakh JEE Main qualifiers only.", "Engineering", 10, 40, 75, "https://jeeadv.ac.in", 17, 25, '["PCM"]', "12th", 75.0, 75.0, 3500, 3500, 1750, 1750, 1750, 1750, 17385, "Online", "ALL", "Must qualify JEE Main first. Max 2 attempts.")
    add("BITSAT 2026", "BITS Pilani Admission Test.", "Engineering", 5, 25, 50, "https://bitsadmission.com", 17, 25, '["PCM"]', "12th", 75.0, 75.0, 3500, 3500, 3500, 3500, 3500, 3500, 2000, "Online", "ALL", "Min 75% in 12th PCM.")
    add("VITEEE 2026", "VIT Engineering Entrance.", "Engineering", 0, 20, 40, "https://viteee.vit.ac.in", 17, 22, '["PCM"]', "12th", 60.0, 60.0, 1350, 1350, 1350, 1350, 1350, 1350, 15000, "Online", "ALL", "Min 60% in PCM.")
    add("SRMJEEE 2026", "SRM Joint Engineering Entrance.", "Engineering", 0, 25, 50, "https://srmist.edu.in", 17, 22, '["PCM"]', "12th", 60.0, 60.0, 1100, 1100, 1100, 1100, 1100, 1100, 8000, "Online", "ALL", "Min 60% in PCM.")
    add("NATA 2026", "National Aptitude Test in Architecture.", "Engineering", 10, 45, 80, "https://nata.in", 17, 25, '["PCM"]', "12th", 50.0, 50.0, 2000, 2000, 2000, 2000, 2000, 2000, 0, "Online", "ALL", "12th with Mathematics.")
    add("CUET UG 2026", "Common University Entrance Test.", "Engineering", 5, 35, 70, "https://cuet.samarth.ac.in", 17, 25, "ALL", "12th", 0, 0, 650, 600, 550, 550, 550, 600, 0, "Online", "ALL", "12th pass.")
    add("JEE Main Paper 2 B.Arch 2026", "JEE Main for Architecture admissions.", "Engineering", -5, 2, 34, "https://jeemain.nta.nic.in", 17, 25, '["PCM"]', "12th", 50.0, 50.0, 1000, 900, 500, 500, 500, 900, 0, "Online", "ALL", "12th with Math. For B.Arch.")

    # ══════════════════════════════════════════════════════════════
    # 2. ENGINEERING (State)
    # ══════════════════════════════════════════════════════════════
    add("MHT-CET 2026", "Maharashtra CET for Engineering & Pharmacy.", "Engineering", -5, 7, 55, "https://cetcell.mahacet.org", 17, 25, '["PCM","PCB"]', "12th", 45.0, 45.0, 800, 600, 400, 400, 400, 600, 200000, "Online", "ALL", "12th PCM or PCB. Min 45%.")
    add("KCET 2026", "Karnataka CET for Engineering.", "Engineering", -2, 15, 45, "https://cetonline.karnataka.gov.in", 17, 25, '["PCM","PCB"]', "12th", 45.0, 45.0, 500, 400, 250, 250, 250, 400, 60000, "Online", "ALL", "Karnataka domicile.")
    add("COMEDK UGET 2026", "Consortium of Medical Engineering Dental Colleges Karnataka.", "Engineering", 5, 30, 60, "https://comedk.org", 17, 25, '["PCM"]', "12th", 45.0, 45.0, 1500, 1500, 1500, 1500, 1500, 1500, 20000, "Online", "ALL", "Karnataka private colleges.")
    add("WBJEE 2026", "West Bengal Joint Entrance Examination.", "Engineering", 5, 25, 50, "https://wbjeeb.nic.in", 17, 25, '["PCM"]', "12th", 45.0, 45.0, 500, 400, 250, 250, 250, 400, 40000, "Offline", "ALL", "WB domicile.")
    add("UPSEE 2026", "Uttar Pradesh State Entrance Exam.", "Engineering", 5, 30, 60, "https://aktu.ac.in", 17, 25, '["PCM"]', "12th", 45.0, 45.0, 500, 400, 250, 250, 250, 400, 50000, "Online", "ALL", "UP domicile.")
    add("GUJCET 2026", "Gujarat Common Entrance Test.", "Engineering", 5, 30, 55, "https://gseb.org", 17, 25, '["PCM"]', "12th", 45.0, 45.0, 400, 300, 200, 200, 200, 300, 30000, "Offline", "ALL", "Gujarat domicile.")
    add("KEAM 2026", "Kerala Engineering Architecture Medical.", "Engineering", 5, 28, 55, "https://cee.kerala.gov.in", 17, 25, '["PCM"]', "12th", 50.0, 50.0, 700, 500, 300, 300, 300, 500, 25000, "Online", "ALL", "Kerala domicile.")
    add("OJEE 2026", "Odisha Joint Entrance Examination.", "Engineering", 5, 30, 55, "https://ojee.nic.in", 17, 25, '["PCM"]', "12th", 45.0, 45.0, 500, 400, 250, 250, 250, 400, 20000, "Online", "ALL", "Odisha domicile.")
    add("TANCET 2026", "Tamil Nadu Common Entrance Test PG.", "Engineering", 10, 45, 85, "https://tancet.annauniv.edu", 0, 0, '["PCM"]', "UG", 0, 0, 500, 500, 250, 250, 250, 500, 0, "Online", "ALL", "B.E/B.Tech for M.E/M.Tech.")
    add("TNEA 2026", "Tamil Nadu Engineering Admissions.", "Engineering", 10, 50, 90, "https://tneaonline.org", 17, 25, '["PCM"]', "12th", 50.0, 50.0, 500, 400, 250, 250, 250, 400, 100000, "Online", "ALL", "TN domicile. Based on 12th marks.")
    add("AP EAMCET 2026", "Andhra Pradesh Engineering Agriculture Medicine CET.", "Engineering", 5, 30, 60, "https://sche.ap.gov.in", 17, 25, '["PCM","PCB"]', "12th", 45.0, 45.0, 500, 400, 250, 250, 250, 400, 80000, "Online", "ALL", "AP domicile.")
    add("TS EAMCET 2026", "Telangana State EAMCET.", "Engineering", 5, 30, 60, "https://tsche.ac.in", 17, 25, '["PCM","PCB"]', "12th", 45.0, 45.0, 500, 400, 250, 250, 250, 400, 80000, "Online", "ALL", "Telangana domicile.")
    add("BCECE 2026", "Bihar Combined Entrance Competitive Exam.", "Engineering", 10, 50, 90, "https://bceceboard.bihar.gov.in", 17, 25, '["PCM","PCB"]', "12th", 45.0, 45.0, 500, 400, 250, 250, 250, 400, 20000, "Online", "ALL", "Bihar domicile.")
    add("MPPET 2026", "MP Pre Engineering Test.", "Engineering", 10, 50, 90, "https://vyapam.nic.in", 17, 25, '["PCM"]', "12th", 45.0, 45.0, 500, 400, 250, 250, 250, 400, 30000, "Online", "ALL", "MP domicile.")
    add("REAP 2026", "Rajasthan Engineering Admission Process.", "Engineering", 10, 50, 90, "https://reapraj.com", 17, 25, '["PCM"]', "12th", 45.0, 45.0, 500, 400, 250, 250, 250, 400, 50000, "Online", "ALL", "Rajasthan domicile.")
    add("GCET Goa 2026", "Goa Common Entrance Test.", "Engineering", 10, 50, 90, "https://dtegoa.gov.in", 17, 25, '["PCM"]', "12th", 45.0, 45.0, 500, 500, 500, 500, 500, 500, 5000, "Online", "ALL", "Goa domicile.")
    add("IPU CET 2026", "Indraprastha University CET.", "Engineering", 5, 35, 70, "https://ipu.ac.in", 17, 25, '["PCM"]', "12th", 50.0, 50.0, 1000, 1000, 500, 500, 500, 1000, 20000, "Online", "ALL", "Delhi/NCR.")
    add("PUCET 2026", "Punjab University Common Entrance Test.", "Engineering", 10, 50, 90, "https://punjabiuniversity.ac.in", 17, 25, '["PCM"]', "12th", 45.0, 45.0, 500, 400, 250, 250, 250, 400, 10000, "Online", "ALL", "Punjab domicile.")
    add("HPCET 2026", "Himachal Pradesh Common Entrance Test.", "Engineering", 10, 50, 90, "https://himtu.ac.in", 17, 25, '["PCM"]', "12th", 45.0, 45.0, 500, 400, 250, 250, 250, 400, 10000, "Online", "ALL", "HP domicile.")
    add("JCECE 2026", "Jharkhand Combined Entrance Exam.", "Engineering", 10, 50, 90, "https://jceceb.jharkhand.gov.in", 17, 25, '["PCM","PCB"]', "12th", 45.0, 45.0, 500, 400, 250, 250, 250, 400, 10000, "Online", "ALL", "Jharkhand domicile.")

    # ══════════════════════════════════════════════════════════════
    # 3. MEDICAL
    # ══════════════════════════════════════════════════════════════
    add("NEET UG 2026", "National exam for MBBS, BDS, BAMS, BHMS.", "Medical", -10, 3, 30, "https://neet.nta.nic.in", 17, 25, '["PCB"]', "12th", 50.0, 50.0, 1700, 1600, 1000, 1000, 1000, 1600, 100000, "Offline", "ALL", "PCB 12th with 50%.")
    add("NEET PG 2026", "MD/MS/PG Diploma for MBBS graduates.", "Medical", 5, 35, 60, "https://nbe.edu.in", 0, 0, "ALL", "UG", 0, 0, 4500, 4500, 4500, 4500, 4500, 4500, 50000, "Online", "ALL", "MBBS + 1 year internship.")
    add("AIIMS BSc Nursing 2026", "AIIMS B.Sc Nursing. Female only.", "Medical", 10, 40, 70, "https://aiimsexams.ac.in", 17, 25, '["PCB"]', "12th", 55.0, 55.0, 1500, 1200, 800, 800, 800, 1200, 1000, "Online", "Female", "Female. PCB 55%.")
    add("GPAT 2026", "Graduate Pharmacy Aptitude Test.", "Medical", 15, 50, 85, "https://gpat.nta.nic.in", 0, 0, '["PCB"]', "UG", 0, 0, 2000, 2000, 1000, 1000, 1000, 1500, 0, "Online", "ALL", "B.Pharma.")
    add("FMGE 2026", "Foreign Medical Graduates Examination.", "Medical", 10, 45, 80, "https://nbe.edu.in", 0, 0, "ALL", "UG", 0, 0, 5000, 5000, 5000, 5000, 5000, 5000, 0, "Online", "ALL", "MBBS from foreign country.")
    add("DNB CET 2026", "Diplomate National Board CET.", "Medical", 10, 45, 80, "https://nbe.edu.in", 0, 0, "ALL", "UG", 0, 0, 4500, 4500, 4500, 4500, 4500, 4500, 0, "Online", "ALL", "MBBS graduates.")
    add("JIPMER PG 2026", "JIPMER Postgraduate Medical Entrance.", "Medical", 10, 45, 85, "https://jipmer.edu.in", 0, 0, "ALL", "UG", 0, 0, 2500, 2500, 1500, 1500, 1500, 2500, 0, "Online", "ALL", "MBBS with 55%.")
    add("NIPER JEE 2026", "National Institute of Pharmaceutical Education.", "Medical", 15, 50, 90, "https://niper.gov.in", 0, 0, '["PCB"]', "UG", 0, 0, 2500, 2500, 1250, 1250, 1250, 2500, 0, "Online", "ALL", "B.Pharma 60%.")
    add("AFMC MBBS 2026", "Armed Forces Medical College.", "Defence", 5, 30, 60, "https://afmc.nic.in", 17, 24, '["PCB"]', "12th", 60.0, 60.0, 0, 0, 0, 0, 0, 0, 130, "Offline", "ALL", "PCB 60%. NEET qualified.")
    add("AIAPGET 2026", "All India Ayush PG Entrance Test.", "Medical", 10, 45, 85, "https://aiapget.nta.nic.in", 0, 0, '["PCB"]', "UG", 0, 0, 1500, 1500, 750, 750, 750, 1500, 0, "Online", "ALL", "BAMS/BUMS/BHMS degree.")
    add("BPT Entrance 2026", "Bachelor of Physiotherapy entrance.", "Medical", 5, 35, 65, "https://nta.nic.in", 17, 25, '["PCB"]', "12th", 50.0, 50.0, 1000, 1000, 500, 500, 500, 1000, 0, "Online", "ALL", "12th PCB.")
    add("BITS HD Pharmacy 2026", "BITS Pilani Higher Degree Pharmacy.", "Medical", 10, 45, 85, "https://bits-pilani.ac.in", 0, 0, '["PCB"]', "UG", 0, 0, 3000, 3000, 3000, 3000, 3000, 3000, 0, "Online", "ALL", "B.Pharma 60%.")

    # ══════════════════════════════════════════════════════════════
    # 4. DEFENCE
    # ══════════════════════════════════════════════════════════════
    add("NDA 2026 (I)", "National Defence Academy.", "Defence", -3, 6, 60, "https://upsc.gov.in", 16, 19, '["PCM"]', "12th", 0, 0, 100, 100, 0, 0, 0, 0, 400, "Offline", "Male", "Male. Age 16.5-19.5.")
    add("NDA 2026 (II)", "NDA Second Examination.", "Defence", 60, 90, 150, "https://upsc.gov.in", 16, 19, '["PCM"]', "12th", 0, 0, 100, 100, 0, 0, 0, 0, 400, "Offline", "Male", "Male. Age 16.5-19.5.")
    add("CDS 2026 (I)", "Combined Defence Services.", "Defence", 5, 30, 65, "https://upsc.gov.in", 20, 25, "ALL", "UG", 0, 0, 200, 200, 0, 0, 0, 200, 500, "Offline", "ALL", "Graduate. IMA 20-25.")
    add("CDS 2026 (II)", "CDS Second exam.", "Defence", 65, 95, 160, "https://upsc.gov.in", 20, 25, "ALL", "UG", 0, 0, 200, 200, 0, 0, 0, 200, 500, "Offline", "ALL", "Graduate.")
    add("AFCAT 2026 (1)", "Air Force Common Admission Test.", "Defence", 0, 20, 50, "https://afcat.cdac.in", 20, 26, "ALL", "UG", 0, 0, 250, 250, 250, 250, 250, 250, 1000, "Online", "ALL", "Graduate 60%.")
    add("AFCAT 2026 (2)", "Air Force CAT Second exam.", "Defence", 60, 90, 140, "https://afcat.cdac.in", 20, 26, "ALL", "UG", 0, 0, 250, 250, 250, 250, 250, 250, 1000, "Online", "ALL", "Graduate 60%.")
    add("Indian Coast Guard Yantrik 2026", "Coast Guard Yantrik.", "Defence", 0, 15, 40, "https://joinindiancoastguard.cdac.in", 18, 22, '["PCM"]', "Diploma", 0, 0, 300, 300, 300, 300, 300, 300, 300, "Online", "Male", "Male. Diploma 60%.")
    add("Indian Coast Guard Navik GD 2026", "Coast Guard Navik GD.", "Defence", 5, 30, 60, "https://joinindiancoastguard.cdac.in", 18, 22, "ALL", "12th", 0, 0, 250, 250, 250, 250, 250, 250, 500, "Online", "Male", "Male. 12th Math/Physics.")
    add("INET 2026", "Indian Navy Entrance Test.", "Defence", 5, 30, 60, "https://joinindiannavy.gov.in", 19, 25, '["PCM"]', "UG", 0, 0, 0, 0, 0, 0, 0, 0, 200, "Online", "ALL", "B.E/B.Tech 60%.")
    add("MNS 2026", "Military Nursing Service.", "Defence", 5, 35, 70, "https://joinindianarmy.nic.in", 17, 25, '["PCB"]', "12th", 50.0, 50.0, 0, 0, 0, 0, 0, 0, 220, "Offline", "Female", "Female. PCB 50%.")
    add("BSF Head Constable 2026", "BSF Head Constable Ministerial.", "Defence", 10, 45, 85, "https://bsf.gov.in", 18, 25, "ALL", "12th", 0, 0, 100, 100, 0, 0, 0, 0, 1000, "Online", "ALL", "12th pass.")
    add("CISF ASI 2026", "CISF Assistant Sub Inspector.", "Defence", 10, 50, 90, "https://cisf.gov.in", 18, 30, "ALL", "12th", 0, 0, 100, 100, 0, 0, 0, 0, 500, "Online", "ALL", "12th pass.")
    add("CRPF ASI 2026", "CRPF Assistant Sub Inspector.", "Defence", 10, 50, 90, "https://crpf.gov.in", 18, 30, "ALL", "12th", 0, 0, 100, 100, 0, 0, 0, 0, 500, "Online", "ALL", "12th pass.")
    add("ITBP Constable 2026", "Indo-Tibetan Border Police Constable.", "Defence", 10, 50, 90, "https://itbpolice.nic.in", 18, 25, "ALL", "10th", 0, 0, 100, 100, 0, 0, 0, 0, 1000, "Online", "ALL", "10th pass.")

    # ══════════════════════════════════════════════════════════════
    # 5. CIVIL SERVICES National
    # ══════════════════════════════════════════════════════════════
    add("UPSC CSE 2026", "Civil Services IAS IPS IFS.", "Government", 4, 34, 73, "https://upsc.gov.in", 21, 32, "ALL", "UG", 0, 0, 100, 100, 0, 0, 0, 100, 1105, "Offline", "ALL", "Graduate. Gen 21-32.")
    add("UPSC CAPF AC 2026", "Central Armed Police Forces.", "Government", 10, 40, 80, "https://upsc.gov.in", 20, 25, "ALL", "UG", 0, 0, 200, 200, 0, 0, 0, 0, 323, "Offline", "ALL", "Graduate. Age 20-25.")
    add("UPSC CMS 2026", "UPSC Combined Medical Services.", "Government", 10, 40, 80, "https://upsc.gov.in", 0, 32, '["PCB"]', "UG", 0, 0, 200, 200, 0, 0, 0, 200, 727, "Offline", "ALL", "MBBS. Age max 32.")
    add("UPSC IES 2026", "UPSC Indian Engineering Services.", "Government", 10, 40, 80, "https://upsc.gov.in", 21, 30, '["PCM"]', "UG", 0, 0, 200, 200, 0, 0, 0, 200, 327, "Offline", "ALL", "B.E/B.Tech. Age 21-30.")
    add("ISRO Scientist 2026", "ISRO Scientist/Engineer SC.", "Government", 10, 45, 80, "https://isro.gov.in", 0, 35, "ALL", "UG", 0, 0, 250, 250, 0, 0, 0, 250, 200, "Online", "ALL", "B.E/B.Tech 65%.")
    add("DRDO CEPTAM 2026", "DRDO Talent Management.", "Government", 10, 50, 90, "https://drdo.gov.in", 18, 28, "ALL", "10th", 0, 0, 100, 100, 0, 0, 0, 0, 1000, "Online", "ALL", "10th to Graduate per post.")

    # ══════════════════════════════════════════════════════════════
    # 6. STATE PSC
    # ══════════════════════════════════════════════════════════════
    add("MPSC Rajyaseva 2026", "Maharashtra PSC State Services.", "Government", 5, 30, 70, "https://mpsc.gov.in", 19, 38, "ALL", "UG", 0, 0, 524, 324, 224, 224, 224, 424, 800, "Online", "ALL", "Graduate. Maharashtra.")
    add("BPSC 2026", "Bihar PSC Combined Exam.", "Government", 10, 45, 85, "https://bpsc.bih.nic.in", 20, 37, "ALL", "UG", 0, 0, 600, 600, 150, 150, 150, 300, 500, "Offline", "ALL", "Graduate. Bihar.")
    add("UPPSC PCS 2026", "UP PSC Provincial Civil Services.", "Government", 10, 45, 90, "https://uppsc.up.nic.in", 21, 40, "ALL", "UG", 0, 0, 100, 100, 0, 0, 0, 0, 400, "Offline", "ALL", "Graduate. UP.")
    add("TNPSC Group 1 2026", "Tamil Nadu PSC Group 1.", "Government", 10, 50, 100, "https://tnpsc.gov.in", 21, 32, "ALL", "UG", 0, 0, 150, 150, 0, 0, 0, 0, 100, "Offline", "ALL", "Graduate. TN.")
    add("TNPSC Group 2 2026", "Tamil Nadu PSC Group 2.", "Government", 10, 50, 95, "https://tnpsc.gov.in", 18, 32, "ALL", "12th", 0, 0, 150, 150, 0, 0, 0, 0, 500, "Online", "ALL", "12th pass. TN.")
    add("KPSC 2026", "Karnataka PSC Group A & B.", "Government", 10, 50, 100, "https://kpsc.kar.nic.in", 21, 35, "ALL", "UG", 0, 0, 200, 200, 100, 100, 100, 200, 300, "Online", "ALL", "Graduate. Karnataka.")
    add("MPPSC 2026", "MP PSC State Services.", "Government", 10, 50, 95, "https://mppsc.mp.gov.in", 21, 40, "ALL", "UG", 0, 0, 500, 250, 0, 0, 0, 0, 300, "Offline", "ALL", "Graduate. MP.")
    add("RPSC RAS 2026", "Rajasthan PSC Administrative Services.", "Government", 10, 50, 100, "https://rpsc.rajasthan.gov.in", 21, 40, "ALL", "UG", 0, 0, 350, 350, 0, 0, 0, 0, 200, "Offline", "ALL", "Graduate. Rajasthan.")
    add("WBPSC WBCS 2026", "West Bengal PSC Civil Services.", "Government", 10, 50, 100, "https://pscwbapplication.in", 21, 36, "ALL", "UG", 0, 0, 210, 210, 0, 0, 0, 0, 400, "Offline", "ALL", "Graduate. WB.")
    add("GPSC 2026", "Gujarat PSC Class 1 & 2.", "Government", 10, 50, 95, "https://gpsc.gujarat.gov.in", 21, 35, "ALL", "UG", 0, 0, 300, 300, 150, 150, 150, 300, 200, "Online", "ALL", "Graduate. Gujarat.")
    add("APPSC Group 1 2026", "Andhra Pradesh PSC Group 1.", "Government", 10, 50, 100, "https://psc.ap.gov.in", 18, 42, "ALL", "UG", 0, 0, 250, 250, 0, 0, 0, 0, 150, "Offline", "ALL", "Graduate. AP.")
    add("TSPSC Group 1 2026", "Telangana PSC Group 1.", "Government", 10, 50, 100, "https://tspsc.gov.in", 18, 44, "ALL", "UG", 0, 0, 200, 200, 100, 100, 100, 200, 100, "Offline", "ALL", "Graduate. Telangana.")
    add("HPSC HCS 2026", "Haryana PSC Civil Services.", "Government", 10, 50, 100, "https://hpsc.gov.in", 21, 42, "ALL", "UG", 0, 0, 500, 125, 0, 0, 0, 0, 100, "Offline", "ALL", "Graduate. Haryana.")
    add("PPSC 2026", "Punjab PSC State Services.", "Government", 10, 50, 100, "https://ppsc.gov.in", 18, 37, "ALL", "UG", 0, 0, 1000, 250, 0, 0, 0, 0, 100, "Offline", "ALL", "Graduate. Punjab.")
    add("JPSC 2026", "Jharkhand PSC Civil Services.", "Government", 10, 55, 105, "https://jpsc.gov.in", 21, 35, "ALL", "UG", 0, 0, 600, 600, 0, 0, 0, 0, 200, "Offline", "ALL", "Graduate. Jharkhand.")
    add("CGPSC 2026", "Chhattisgarh PSC State Services.", "Government", 10, 55, 105, "https://psc.cg.gov.in", 21, 30, "ALL", "UG", 0, 0, 400, 400, 0, 0, 0, 0, 100, "Offline", "ALL", "Graduate. CG.")
    add("UKPSC 2026", "Uttarakhand PSC Civil Services.", "Government", 10, 55, 105, "https://psc.uk.gov.in", 21, 42, "ALL", "UG", 0, 0, 150, 60, 0, 0, 0, 0, 100, "Offline", "ALL", "Graduate. Uttarakhand.")
    add("OPSC OAS 2026", "Odisha PSC Administrative Services.", "Government", 10, 55, 105, "https://opsc.gov.in", 21, 38, "ALL", "UG", 0, 0, 200, 200, 0, 0, 0, 0, 200, "Offline", "ALL", "Graduate. Odisha.")

    # ══════════════════════════════════════════════════════════════
    # 7. SSC
    # ══════════════════════════════════════════════════════════════
    add("SSC CGL 2026", "SSC Combined Graduate Level.", "Government", -2, 14, 60, "https://ssc.nic.in", 18, 32, "ALL", "UG", 0, 0, 100, 100, 0, 0, 0, 0, 17727, "Online", "ALL", "Graduate. Age 18-32.")
    add("SSC CHSL 2026", "SSC Combined Higher Secondary Level.", "Government", 0, 20, 55, "https://ssc.nic.in", 18, 27, "ALL", "12th", 0, 0, 100, 100, 0, 0, 0, 0, 10000, "Online", "ALL", "12th pass.")
    add("SSC MTS 2026", "SSC Multi-Tasking Staff.", "Government", 5, 35, 70, "https://ssc.nic.in", 18, 25, "ALL", "10th", 0, 0, 100, 100, 0, 0, 0, 0, 15000, "Online", "ALL", "10th pass.")
    add("SSC CPO 2026", "SSC Central Police Organisation SI.", "Government", 5, 35, 70, "https://ssc.nic.in", 20, 25, "ALL", "UG", 0, 0, 100, 100, 0, 0, 0, 0, 4000, "Online", "ALL", "Graduate.")
    add("SSC GD Constable 2026", "SSC GD Constable in CAPFs.", "Government", 10, 50, 90, "https://ssc.nic.in", 18, 23, "ALL", "10th", 0, 0, 100, 100, 0, 0, 0, 0, 26146, "Online", "ALL", "10th pass.")
    add("SSC JE 2026", "SSC Junior Engineer.", "Government", 5, 35, 70, "https://ssc.nic.in", 18, 32, '["PCM"]', "Diploma", 0, 0, 100, 100, 0, 0, 0, 0, 1000, "Online", "ALL", "Diploma/Degree Engineering.")
    add("SSC Stenographer 2026", "SSC Stenographer Grade C and D.", "Government", 5, 35, 70, "https://ssc.nic.in", 18, 30, "ALL", "12th", 0, 0, 100, 100, 0, 0, 0, 0, 2000, "Online", "ALL", "12th pass. Shorthand required.")
    add("SSC Selection Post 2026", "SSC Selection Post Phase XII.", "Government", 5, 35, 65, "https://ssc.nic.in", 18, 32, "ALL", "10th", 0, 0, 100, 100, 0, 0, 0, 0, 5000, "Online", "ALL", "10th/12th/Graduate per post.")

    # ══════════════════════════════════════════════════════════════
    # 8. RAILWAYS
    # ══════════════════════════════════════════════════════════════
    add("RRB NTPC 2026", "Railway NTPC Clerk, Station Master.", "Railway", 15, 50, 90, "https://indianrailways.gov.in", 18, 36, "ALL", "12th", 0, 0, 500, 400, 250, 250, 250, 400, 35208, "Online", "ALL", "12th/Graduate per post.")
    add("RRB Group D 2026", "Railway Group D Track Maintainer.", "Railway", 20, 60, 100, "https://indianrailways.gov.in", 18, 36, "ALL", "10th", 0, 0, 500, 400, 250, 250, 250, 400, 103769, "Online", "ALL", "10th + ITI.")
    add("RRB JE 2026", "Railway Junior Engineer.", "Railway", 15, 55, 95, "https://indianrailways.gov.in", 18, 33, '["PCM"]', "Diploma", 0, 0, 500, 400, 250, 250, 250, 400, 7000, "Online", "ALL", "Diploma/Degree Engineering.")
    add("RRB ALP 2026", "Railway Assistant Loco Pilot.", "Railway", 15, 55, 95, "https://indianrailways.gov.in", 18, 28, '["PCM"]', "10th", 0, 0, 500, 400, 250, 250, 250, 400, 5000, "Online", "ALL", "10th + ITI.")
    add("RRB Paramedical 2026", "Railway Paramedical Staff.", "Railway", 20, 60, 100, "https://indianrailways.gov.in", 18, 38, '["PCB"]', "12th", 0, 0, 500, 400, 250, 250, 250, 400, 1000, "Online", "ALL", "12th PCB + medical qualification.")
    add("RRB RPF Constable 2026", "Railway Protection Force Constable.", "Railway", 10, 50, 90, "https://indianrailways.gov.in", 18, 25, "ALL", "10th", 0, 0, 500, 400, 250, 250, 250, 400, 4660, "Online", "ALL", "10th pass.")
    add("RRB RPF SI 2026", "Railway Protection Force Sub Inspector.", "Railway", 10, 50, 90, "https://indianrailways.gov.in", 20, 25, "ALL", "UG", 0, 0, 500, 400, 250, 250, 250, 400, 452, "Online", "ALL", "Graduate.")

    # ══════════════════════════════════════════════════════════════
    # 9. BANKING
    # ══════════════════════════════════════════════════════════════
    add("IBPS PO 2026", "IBPS PO in 11 PSBs.", "Banking", -1, 19, 65, "https://ibps.in", 20, 30, "ALL", "UG", 0, 0, 850, 850, 175, 175, 175, 850, 4455, "Online", "ALL", "Graduate.")
    add("IBPS Clerk 2026", "IBPS Clerical Cadre.", "Banking", 5, 30, 70, "https://ibps.in", 20, 28, "ALL", "12th", 0, 0, 850, 850, 175, 175, 175, 850, 6128, "Online", "ALL", "12th pass.")
    add("IBPS RRB PO 2026", "IBPS RRB Officer Scale I.", "Banking", 5, 35, 70, "https://ibps.in", 18, 30, "ALL", "UG", 0, 0, 850, 850, 175, 175, 175, 850, 5000, "Online", "ALL", "Graduate.")
    add("IBPS RRB Clerk 2026", "IBPS RRB Office Assistant.", "Banking", 5, 35, 70, "https://ibps.in", 18, 28, "ALL", "12th", 0, 0, 850, 850, 175, 175, 175, 850, 8000, "Online", "ALL", "12th pass.")
    add("IBPS SO 2026", "IBPS Specialist Officer.", "Banking", 5, 35, 70, "https://ibps.in", 20, 30, "ALL", "UG", 0, 0, 850, 850, 175, 175, 175, 850, 1000, "Online", "ALL", "Graduate in relevant field.")
    add("SBI PO 2026", "SBI Probationary Officer.", "Banking", 0, 25, 60, "https://sbi.co.in", 21, 30, "ALL", "UG", 0, 0, 750, 750, 0, 0, 0, 750, 2000, "Online", "ALL", "Graduate.")
    add("SBI Clerk 2026", "SBI Junior Associate.", "Banking", 10, 40, 75, "https://sbi.co.in", 20, 28, "ALL", "12th", 0, 0, 750, 750, 0, 0, 0, 750, 8000, "Online", "ALL", "12th pass.")
    add("SBI SO 2026", "SBI Specialist Officer.", "Banking", 5, 35, 65, "https://sbi.co.in", 21, 35, "ALL", "UG", 0, 0, 750, 750, 0, 0, 0, 750, 500, "Online", "ALL", "Professional degree.")
    add("NABARD Grade A 2026", "NABARD Assistant Manager.", "Banking", 15, 45, 80, "https://nabard.org", 21, 30, "ALL", "UG", 0, 0, 800, 800, 150, 150, 150, 800, 150, "Online", "ALL", "Graduate 50%.")
    add("NABARD Grade B 2026", "NABARD Manager.", "Banking", 15, 45, 80, "https://nabard.org", 21, 35, "ALL", "UG", 0, 0, 850, 850, 200, 200, 200, 850, 0, "Online", "ALL", "Graduate/PG 60%.")
    add("RBI Grade B 2026", "RBI Grade B Officer.", "Banking", 10, 40, 75, "https://rbi.org.in", 21, 30, "ALL", "UG", 0, 0, 850, 850, 100, 100, 100, 850, 291, "Online", "ALL", "Graduate 60%.")
    add("RBI Assistant 2026", "RBI Assistant clerical.", "Banking", 10, 40, 75, "https://rbi.org.in", 20, 28, "ALL", "UG", 0, 0, 450, 450, 0, 0, 0, 450, 900, "Online", "ALL", "Graduate.")
    add("LIC AAO 2026", "LIC Assistant Administrative Officer.", "Banking", 5, 35, 70, "https://licindia.in", 21, 30, "ALL", "UG", 0, 0, 700, 700, 0, 0, 0, 700, 300, "Online", "ALL", "Graduate.")
    add("LIC ADO 2026", "LIC Apprentice Development Officer.", "Banking", 5, 35, 70, "https://licindia.in", 21, 30, "ALL", "UG", 0, 0, 600, 600, 0, 0, 0, 600, 5000, "Online", "ALL", "Graduate.")
    add("SIDBI Grade A 2026", "SIDBI Officer Grade A.", "Banking", 10, 40, 75, "https://sidbi.in", 21, 30, "ALL", "UG", 0, 0, 800, 800, 150, 150, 150, 800, 100, "Online", "ALL", "Graduate 60%.")
    add("SEBI Grade A 2026", "SEBI Officer Grade A.", "Banking", 10, 40, 75, "https://sebi.gov.in", 21, 30, "ALL", "UG", 0, 0, 1000, 1000, 100, 100, 100, 1000, 120, "Online", "ALL", "Graduate/PG/CA/CFA.")
    add("IRDA Assistant Manager 2026", "Insurance Regulatory Authority officer.", "Banking", 10, 45, 85, "https://irdai.gov.in", 21, 30, "ALL", "UG", 0, 0, 750, 750, 0, 0, 0, 750, 0, "Online", "ALL", "Graduate.")
    add("PFRDA Grade A 2026", "Pension Fund Regulatory officer.", "Banking", 10, 45, 85, "https://pfrda.org.in", 21, 30, "ALL", "UG", 0, 0, 800, 800, 0, 0, 0, 800, 0, "Online", "ALL", "Graduate.")

    # ══════════════════════════════════════════════════════════════
    # 10. LAW
    # ══════════════════════════════════════════════════════════════
    add("CLAT 2026", "Common Law Admission Test for 22 NLUs.", "Law", -5, 24, 46, "https://consortiumofnlus.ac.in", 0, 45, "ALL", "12th", 0, 45.0, 4000, 3500, 3500, 3500, 3500, 3500, 2500, "Online", "ALL", "12th 45%.")
    add("AILET 2026", "All India Law Entrance for NLU Delhi.", "Law", 0, 20, 40, "https://nludelhi.ac.in", 17, 0, "ALL", "12th", 0, 50.0, 3500, 3000, 3000, 3000, 3000, 3000, 110, "Offline", "ALL", "12th 50%.")
    add("CLAT PG 2026", "CLAT PG for LLM at NLUs.", "Law", -5, 24, 46, "https://consortiumofnlus.ac.in", 0, 0, "ALL", "UG", 0, 0, 4000, 3500, 3500, 3500, 3500, 3500, 0, "Online", "ALL", "LLB 50%.")
    add("MHCET Law 2026", "Maharashtra Law CET.", "Law", 5, 30, 55, "https://mahacet.org", 0, 30, "ALL", "12th", 0, 45.0, 800, 600, 400, 400, 400, 600, 5000, "Online", "ALL", "12th 45%. Maharashtra.")
    add("LSAT India 2026", "Law School Admission Test India.", "Law", 0, 30, 55, "https://discoverlaw.in", 0, 0, "ALL", "12th", 0, 45.0, 3999, 3999, 3999, 3999, 3999, 3999, 0, "Online", "ALL", "12th pass.")
    add("SLAT 2026", "Symbiosis Law Admission Test.", "Law", 5, 30, 55, "https://symlaw.ac.in", 17, 22, "ALL", "12th", 0, 45.0, 1750, 1750, 1750, 1750, 1750, 1750, 500, "Online", "ALL", "12th 45%.")
    add("AP LAWCET 2026", "Andhra Pradesh Law CET.", "Law", 5, 35, 65, "https://lawcet.apsche.ac.in", 0, 0, "ALL", "12th", 0, 45.0, 400, 400, 200, 200, 200, 400, 0, "Online", "ALL", "AP domicile.")
    add("TS LAWCET 2026", "Telangana Law CET.", "Law", 5, 35, 65, "https://tslawcet.org", 0, 0, "ALL", "12th", 0, 45.0, 400, 400, 200, 200, 200, 400, 0, "Online", "ALL", "Telangana domicile.")
    add("DU LLB 2026", "Delhi University LLB entrance.", "Law", 5, 35, 65, "https://du.ac.in", 0, 0, "ALL", "UG", 0, 0, 1500, 1500, 750, 750, 750, 1500, 0, "Online", "ALL", "Graduate for 3-year LLB.")
    add("BHU LLB 2026", "BHU Law entrance.", "Law", 10, 45, 85, "https://bhuonline.in", 0, 0, "ALL", "12th", 0, 45.0, 600, 600, 300, 300, 300, 600, 0, "Online", "ALL", "12th (5yr) or Graduate (3yr).")

    # ══════════════════════════════════════════════════════════════
    # 11. MANAGEMENT / MBA
    # ══════════════════════════════════════════════════════════════
    add("CAT 2026", "Common Admission Test for IIMs.", "Management", 15, 46, 180, "https://iimcat.ac.in", 0, 0, "ALL", "UG", 0, 0, 2400, 1200, 1200, 1200, 1200, 1200, 0, "Online", "ALL", "Graduate 50%.")
    add("XAT 2026", "Xavier Aptitude Test for XLRI.", "Management", 20, 55, 100, "https://xatonline.in", 0, 0, "ALL", "UG", 0, 0, 2000, 2000, 2000, 2000, 2000, 2000, 0, "Online", "ALL", "Graduate.")
    add("MAT 2026", "Management Aptitude Test AIMA.", "Management", 0, 30, 45, "https://mat.aima.in", 0, 0, "ALL", "UG", 0, 0, 1900, 1900, 1900, 1900, 1900, 1900, 0, "Online", "ALL", "Graduate.")
    add("SNAP 2026", "Symbiosis National Aptitude Test.", "Management", 15, 55, 100, "https://snaptest.org", 0, 0, "ALL", "UG", 0, 0, 1750, 1750, 1750, 1750, 1750, 1750, 0, "Online", "ALL", "Graduate 50%.")
    add("NMAT 2026", "NMIMS Management Aptitude Test.", "Management", 5, 45, 90, "https://nmat.org.in", 0, 0, "ALL", "UG", 0, 0, 2300, 2300, 2300, 2300, 2300, 2300, 0, "Online", "ALL", "Graduate. 3 attempts.")
    add("IIFT 2026", "Indian Institute of Foreign Trade MBA.", "Management", 10, 45, 90, "https://iift.nta.nic.in", 0, 0, "ALL", "UG", 0, 0, 2000, 2000, 2000, 2000, 2000, 2000, 0, "Online", "ALL", "Graduate.")
    add("CMAT 2026", "Common Management Admission Test NTA.", "Management", 5, 40, 80, "https://cmat.nta.nic.in", 0, 0, "ALL", "UG", 0, 0, 2000, 1000, 1000, 1000, 1000, 1000, 0, "Online", "ALL", "Graduate.")
    add("ATMA 2026", "AIMS Test for Management.", "Management", 5, 40, 75, "https://atmaaims.com", 0, 0, "ALL", "UG", 0, 0, 1600, 1600, 1600, 1600, 1600, 1600, 0, "Online", "ALL", "Graduate.")
    add("MICAT 2026", "MICA Admission Test.", "Management", 5, 40, 75, "https://mica.ac.in", 0, 0, "ALL", "UG", 0, 0, 1965, 1965, 1965, 1965, 1965, 1965, 0, "Online", "ALL", "Graduate.")
    add("MAH MBA CET 2026", "Maharashtra MBA CET.", "Management", 5, 35, 70, "https://mahacet.org", 0, 0, "ALL", "UG", 0, 0, 1000, 800, 600, 600, 600, 800, 0, "Online", "ALL", "Graduate. Maharashtra.")
    add("KMAT Karnataka 2026", "Karnataka Management Aptitude Test.", "Management", 5, 40, 75, "https://kmatindia.com", 0, 0, "ALL", "UG", 0, 0, 1000, 1000, 1000, 1000, 1000, 1000, 0, "Online", "ALL", "Graduate.")
    add("TISS NET 2026", "TISS National Entrance Test.", "Management", 5, 40, 75, "https://tiss.edu", 0, 0, "ALL", "UG", 0, 0, 1050, 1050, 525, 525, 525, 1050, 0, "Online", "ALL", "Graduate 45%.")
    add("IGNOU OPENMAT 2026", "IGNOU Open Management Test.", "Management", 5, 40, 75, "https://ignou.ac.in", 0, 0, "ALL", "UG", 0, 0, 1000, 1000, 1000, 1000, 1000, 1000, 0, "Online", "ALL", "Graduate.")
    add("UPSEE MBA 2026", "UP State Entrance for MBA.", "Management", 5, 35, 70, "https://aktu.ac.in", 0, 0, "ALL", "UG", 0, 0, 500, 400, 250, 250, 250, 400, 0, "Online", "ALL", "Graduate.")

    # ══════════════════════════════════════════════════════════════
    # 12. TEACHING
    # ══════════════════════════════════════════════════════════════
    add("CTET 2026", "Central Teacher Eligibility Test.", "Teaching", 20, 50, 100, "https://ctet.nic.in", 0, 0, "ALL", "UG", 0, 0, 1000, 1000, 500, 500, 500, 1000, 0, "Online", "ALL", "Paper 1: 12th+D.El.Ed. Paper 2: Graduate+B.Ed.")
    add("UGC NET 2026", "National Eligibility Test JRF/Lectureship.", "Teaching", 10, 60, 120, "https://ugcnet.nta.nic.in", 0, 0, "ALL", "PG", 0, 0, 1100, 1100, 275, 275, 275, 1100, 0, "Online", "ALL", "PG 55%.")
    add("DSSSB TGT/PGT 2026", "Delhi Govt Teacher recruitment.", "Teaching", 25, 65, 110, "https://dsssb.delhi.gov.in", 21, 36, "ALL", "UG", 0, 0, 500, 250, 250, 250, 250, 250, 3000, "Online", "ALL", "Graduate+B.Ed.")
    add("KVS TGT/PGT 2026", "Kendriya Vidyalaya Teachers.", "Teaching", 20, 60, 100, "https://kvsangathan.nic.in", 0, 35, "ALL", "UG", 0, 0, 1500, 750, 750, 750, 750, 750, 6000, "Online", "ALL", "B.Ed required.")
    add("NVS TGT/PGT 2026", "Navodaya Vidyalaya Teachers.", "Teaching", 20, 60, 100, "https://navodaya.gov.in", 0, 35, "ALL", "UG", 0, 0, 1000, 500, 500, 500, 500, 500, 2000, "Online", "ALL", "Graduate+B.Ed.")
    add("HTET 2026", "Haryana TET.", "Teaching", 10, 45, 80, "https://bseh.org.in", 0, 0, "ALL", "UG", 0, 0, 700, 700, 350, 350, 350, 700, 0, "Online", "ALL", "Haryana domicile.")
    add("REET 2026", "Rajasthan TET.", "Teaching", 10, 50, 90, "https://rajeduboard.rajasthan.gov.in", 0, 0, "ALL", "UG", 0, 0, 550, 490, 490, 490, 490, 490, 0, "Online", "ALL", "Rajasthan domicile.")
    add("MAHATET 2026", "Maharashtra TET.", "Teaching", 10, 50, 90, "https://mahatet.in", 0, 0, "ALL", "UG", 0, 0, 500, 450, 400, 400, 400, 450, 0, "Online", "ALL", "Maharashtra domicile.")
    add("UP TET 2026", "UP Teacher Eligibility Test.", "Teaching", 10, 50, 90, "https://updeled.gov.in", 0, 0, "ALL", "UG", 0, 0, 600, 600, 0, 0, 0, 0, 0, "Online", "ALL", "UP domicile.")
    add("MP TET 2026", "MP Teacher Eligibility Test.", "Teaching", 10, 50, 90, "https://vimarsha.mp.gov.in", 0, 0, "ALL", "UG", 0, 0, 500, 500, 250, 250, 250, 500, 0, "Online", "ALL", "MP domicile.")
    add("Bihar TET 2026", "Bihar TET.", "Teaching", 10, 50, 90, "https://biharboardonline.bihar.gov.in", 0, 0, "ALL", "UG", 0, 0, 500, 500, 250, 250, 250, 500, 0, "Online", "ALL", "Bihar domicile.")
    add("TN TET 2026", "Tamil Nadu TET.", "Teaching", 10, 50, 90, "https://trb.tn.nic.in", 0, 0, "ALL", "UG", 0, 0, 500, 500, 250, 250, 250, 500, 0, "Online", "ALL", "TN domicile.")
    add("AP TET 2026", "Andhra Pradesh TET.", "Teaching", 10, 50, 90, "https://aptet.apcfss.in", 0, 0, "ALL", "UG", 0, 0, 500, 500, 250, 250, 250, 500, 0, "Online", "ALL", "AP domicile.")
    add("TS TET 2026", "Telangana TET.", "Teaching", 10, 50, 90, "https://tstet.cgg.gov.in", 0, 0, "ALL", "UG", 0, 0, 500, 500, 250, 250, 250, 500, 0, "Online", "ALL", "Telangana domicile.")
    add("Karnataka TET 2026", "Karnataka TET.", "Teaching", 10, 50, 90, "https://schooleducation.kar.nic.in", 0, 0, "ALL", "UG", 0, 0, 500, 500, 250, 250, 250, 500, 0, "Online", "ALL", "Karnataka domicile.")

    # ══════════════════════════════════════════════════════════════
    # 13. ENGINEERING PG + SCIENCE RESEARCH
    # ══════════════════════════════════════════════════════════════
    add("GATE 2027", "Graduate Aptitude Test for M.Tech and PSUs.", "Engineering", 10, 40, 120, "https://gate2027.iitr.ac.in", 0, 0, "ALL", "UG", 0, 0, 1800, 900, 900, 900, 900, 900, 0, "Online", "ALL", "B.E/B.Tech 3rd year or passed.")
    add("JEST 2026", "Joint Entrance Screening Test PhD.", "Science", 10, 45, 85, "https://jest.org.in", 0, 0, '["PCM"]', "UG", 0, 0, 0, 0, 0, 0, 0, 0, 0, "Online", "ALL", "BSc/BE in Physics or CS.")
    add("JAM 2026", "Joint Admission Test for MSc at IITs.", "Science", 10, 40, 85, "https://jam.iitm.ac.in", 0, 0, '["PCM","PCB"]', "UG", 0, 0, 1800, 900, 900, 900, 900, 900, 0, "Online", "ALL", "BSc in relevant subject.")
    add("CSIR NET 2026", "CSIR NET Science JRF/Lectureship.", "Science", 10, 55, 110, "https://csirhrdg.res.in", 0, 28, '["PCM","PCB"]', "UG", 0, 0, 1100, 550, 550, 550, 550, 550, 0, "Online", "ALL", "BSc/MSc Science.")
    add("TIFR GS 2026", "TIFR Graduate School.", "Science", 10, 50, 95, "https://univ.tifr.res.in", 0, 0, '["PCM","PCB"]', "UG", 0, 0, 0, 0, 0, 0, 0, 0, 0, "Online", "ALL", "BSc/BE for PhD.")
    add("IISc Research 2026", "IISc Research admissions.", "Science", 10, 45, 85, "https://iisc.ac.in", 0, 0, '["PCM","PCB"]', "UG", 0, 0, 800, 400, 400, 400, 400, 400, 0, "Online", "ALL", "BSc/BE with GATE/JAM.")
    add("KVPY 2026", "Kishore Vaigyanik Protsahan Yojana.", "Science", 5, 40, 80, "https://kvpy.iisc.ac.in", 0, 0, '["PCM","PCB"]', "12th", 60.0, 0, 0, 0, 0, 0, 0, 0, 0, "Online", "ALL", "11th/12th Science. Scholarship.")
    add("NTSE 2026", "National Talent Search Examination.", "Science", 5, 40, 80, "https://ncert.nic.in", 14, 18, "ALL", "10th", 0, 0, 0, 0, 0, 0, 0, 0, 0, "Offline", "ALL", "Class 10 students.")

    # ══════════════════════════════════════════════════════════════
    # 14. DESIGN & FASHION
    # ══════════════════════════════════════════════════════════════
    add("NID DAT 2026", "National Institute of Design Aptitude Test.", "Design", 10, 45, 85, "https://admissions.nid.edu", 0, 0, "ALL", "12th", 0, 0, 3500, 3500, 3500, 3500, 3500, 3500, 0, "Online", "ALL", "12th for B.Des. Graduate for M.Des.")
    add("UCEED 2026", "UG Common Entrance Exam Design IITs.", "Design", 5, 35, 70, "https://uceed.iitb.ac.in", 17, 25, "ALL", "12th", 0, 0, 2100, 1050, 1050, 1050, 1050, 1050, 0, "Online", "ALL", "12th pass.")
    add("CEED 2026", "Common Entrance Exam Design M.Des IITs.", "Design", 5, 35, 70, "https://ceed.iitb.ac.in", 0, 0, "ALL", "UG", 0, 0, 3000, 1500, 1500, 1500, 1500, 1500, 0, "Online", "ALL", "Graduate.")
    add("NIFT Entrance 2026", "National Institute of Fashion Technology.", "Design", 10, 45, 85, "https://nift.ac.in", 0, 0, "ALL", "12th", 0, 0, 3000, 3000, 3000, 3000, 3000, 3000, 0, "Online", "ALL", "12th for UG. Graduate for PG.")
    add("Pearl Academy 2026", "Pearl Academy Design entrance.", "Design", 5, 40, 80, "https://pearlacademy.com", 0, 0, "ALL", "12th", 0, 0, 2500, 2500, 2500, 2500, 2500, 2500, 0, "Online", "ALL", "12th pass.")
    add("Symbiosis Design 2026", "Symbiosis Institute of Design.", "Design", 5, 40, 80, "https://sid.edu.in", 0, 0, "ALL", "12th", 0, 0, 1750, 1750, 1750, 1750, 1750, 1750, 0, "Online", "ALL", "12th pass.")

    # ══════════════════════════════════════════════════════════════
    # 15. AGRICULTURE
    # ══════════════════════════════════════════════════════════════
    add("ICAR AIEEA 2026", "ICAR All India Entrance Examination.", "Agriculture", 10, 45, 85, "https://icar.nta.nic.in", 17, 25, '["PCB","PCM"]', "12th", 50.0, 50.0, 1000, 1000, 500, 500, 500, 1000, 0, "Online", "ALL", "12th PCB/PCM 50%.")
    add("BHU Agriculture 2026", "BHU Agriculture entrance.", "Agriculture", 10, 45, 85, "https://bhuonline.in", 17, 25, '["PCB","PCM"]', "12th", 50.0, 50.0, 600, 600, 300, 300, 300, 600, 0, "Online", "ALL", "12th PCB/PCM.")
    add("RAEO 2026", "Rural Agriculture Extension Officer.", "Agriculture", 10, 50, 90, "https://mpesb.mp.gov.in", 21, 40, '["PCB","PCM"]', "UG", 0, 0, 500, 500, 250, 250, 250, 500, 0, "Online", "ALL", "B.Sc Agriculture.")
    add("IARI PhD 2026", "Indian Agricultural Research Institute PhD.", "Agriculture", 10, 50, 95, "https://iari.res.in", 0, 0, '["PCB","PCM"]', "PG", 0, 0, 800, 800, 400, 400, 400, 800, 0, "Online", "ALL", "MSc Agriculture.")
    add("PAU Entrance 2026", "Punjab Agricultural University.", "Agriculture", 10, 50, 90, "https://pau.edu", 17, 25, '["PCB","PCM"]', "12th", 50.0, 50.0, 600, 600, 300, 300, 300, 600, 0, "Online", "ALL", "12th PCB/PCM. Punjab.")

    # ══════════════════════════════════════════════════════════════
    # 16. POLICE
    # ══════════════════════════════════════════════════════════════
    add("Delhi Police Constable 2026", "Delhi Police Constable Executive.", "Police", 10, 50, 90, "https://delhipolice.gov.in", 18, 25, "ALL", "12th", 0, 0, 100, 100, 0, 0, 0, 0, 5000, "Online", "ALL", "12th pass.")
    add("UP Police Constable 2026", "UP Police Constable.", "Police", 10, 50, 90, "https://uppbpb.gov.in", 18, 22, "ALL", "12th", 0, 0, 400, 400, 0, 0, 0, 0, 60000, "Online", "ALL", "12th pass.")
    add("MP Police Constable 2026", "MP Police Constable.", "Police", 10, 50, 90, "https://mppolice.gov.in", 18, 25, "ALL", "12th", 0, 0, 500, 500, 0, 0, 0, 0, 7000, "Online", "ALL", "12th pass.")
    add("Rajasthan Police 2026", "Rajasthan Police Constable.", "Police", 10, 50, 90, "https://police.rajasthan.gov.in", 18, 23, "ALL", "10th", 0, 0, 400, 400, 0, 0, 0, 0, 3500, "Online", "ALL", "10th pass.")
    add("Bihar Police Constable 2026", "Bihar Police Constable.", "Police", 10, 50, 90, "https://csbc.bih.nic.in", 18, 25, "ALL", "12th", 0, 0, 0, 0, 0, 0, 0, 0, 20000, "Online", "ALL", "12th pass.")
    add("Maharashtra Police 2026", "Maharashtra Police Constable.", "Police", 10, 50, 90, "https://mahapolice.gov.in", 18, 28, "ALL", "12th", 0, 0, 0, 0, 0, 0, 0, 0, 10000, "Online", "ALL", "12th pass.")
    add("MPSC Police SI 2026", "Maharashtra Police Sub-Inspector.", "Police", 10, 50, 90, "https://mpsc.gov.in", 19, 31, "ALL", "UG", 0, 0, 524, 324, 224, 224, 224, 424, 800, "Online", "ALL", "Graduate.")
    add("Haryana Police 2026", "Haryana Police Constable.", "Police", 10, 50, 90, "https://hssc.gov.in", 18, 25, "ALL", "10th", 0, 0, 500, 125, 0, 0, 0, 0, 5000, "Online", "ALL", "10th pass.")
    add("Punjab Police 2026", "Punjab Police Constable.", "Police", 10, 50, 90, "https://punjabpolice.gov.in", 18, 28, "ALL", "10th", 0, 0, 0, 0, 0, 0, 0, 0, 2000, "Online", "ALL", "10th pass.")
    add("Gujarat Police 2026", "Gujarat Police Constable.", "Police", 10, 50, 90, "https://ojas.gujarat.gov.in", 18, 33, "ALL", "12th", 0, 0, 0, 0, 0, 0, 0, 0, 8000, "Online", "ALL", "12th pass.")
    add("Karnataka Police 2026", "Karnataka Police Constable.", "Police", 10, 50, 90, "https://ksp.karnataka.gov.in", 18, 25, "ALL", "10th", 0, 0, 0, 0, 0, 0, 0, 0, 4000, "Online", "ALL", "10th pass.")

    # ══════════════════════════════════════════════════════════════
    # 17. COMMERCE & CA
    # ══════════════════════════════════════════════════════════════
    add("CA Foundation 2026", "Chartered Accountancy Foundation ICAI.", "Commerce", 10, 45, 85, "https://icai.org", 0, 0, '["Commerce"]', "12th", 0, 0, 1500, 1500, 1500, 1500, 1500, 1500, 0, "Online", "ALL", "12th pass.")
    add("CA Intermediate 2026", "CA Intermediate exam.", "Commerce", 10, 50, 90, "https://icai.org", 0, 0, '["Commerce"]', "12th", 0, 0, 1500, 1500, 1500, 1500, 1500, 1500, 0, "Online", "ALL", "CA Foundation cleared.")
    add("CA Final 2026", "CA Final examination.", "Commerce", 10, 50, 90, "https://icai.org", 0, 0, '["Commerce"]', "UG", 0, 0, 1500, 1500, 1500, 1500, 1500, 1500, 0, "Online", "ALL", "CA Intermediate cleared.")
    add("CMA Foundation 2026", "Cost Management Accountant Foundation.", "Commerce", 10, 45, 85, "https://icmai.in", 0, 0, '["Commerce"]', "12th", 0, 0, 1200, 1200, 1200, 1200, 1200, 1200, 0, "Online", "ALL", "12th pass.")
    add("CMA Intermediate 2026", "CMA Intermediate exam.", "Commerce", 10, 50, 90, "https://icmai.in", 0, 0, '["Commerce"]', "12th", 0, 0, 1200, 1200, 1200, 1200, 1200, 1200, 0, "Online", "ALL", "CMA Foundation cleared.")
    add("CS Foundation 2026", "Company Secretary Foundation ICSI.", "Commerce", 10, 45, 85, "https://icsi.edu", 0, 0, '["Commerce"]', "12th", 0, 0, 1500, 1500, 1500, 1500, 1500, 1500, 0, "Online", "ALL", "12th pass.")
    add("CS Executive 2026", "Company Secretary Executive.", "Commerce", 10, 50, 90, "https://icsi.edu", 0, 0, '["Commerce"]', "12th", 0, 0, 1500, 1500, 1500, 1500, 1500, 1500, 0, "Online", "ALL", "CS Foundation cleared.")

    # ══════════════════════════════════════════════════════════════
    # 18. ARTS & LIBERAL
    # ══════════════════════════════════════════════════════════════
    add("IIMC Entrance 2026", "Indian Institute of Mass Communication.", "Arts", 10, 50, 90, "https://iimc.nic.in", 0, 0, "ALL", "UG", 0, 0, 1800, 1800, 900, 900, 900, 1800, 0, "Online", "ALL", "Graduate.")
    add("ACJ Entrance 2026", "Asian College of Journalism.", "Arts", 10, 50, 90, "https://asianmedia.in", 0, 0, "ALL", "UG", 0, 0, 1000, 1000, 1000, 1000, 1000, 1000, 0, "Online", "ALL", "Graduate.")
    add("TISS Admissions 2026", "Tata Institute of Social Sciences.", "Arts", 10, 50, 90, "https://tiss.edu", 0, 0, "ALL", "UG", 0, 0, 1050, 1050, 525, 525, 525, 1050, 0, "Online", "ALL", "Graduate 45%.")
    add("DU Entrance 2026", "Delhi University CUET admissions.", "Arts", 5, 35, 70, "https://du.ac.in", 17, 25, "ALL", "12th", 0, 45.0, 650, 600, 550, 550, 550, 600, 0, "Online", "ALL", "12th pass.")
    add("BHU UET 2026", "Banaras Hindu University entrance.", "Arts", 10, 45, 85, "https://bhuonline.in", 17, 25, "ALL", "12th", 0, 45.0, 600, 600, 300, 300, 300, 600, 0, "Online", "ALL", "12th for UG.")
    add("JNU Entrance 2026", "Jawaharlal Nehru University.", "Arts", 10, 45, 85, "https://jnu.ac.in", 0, 0, "ALL", "12th", 0, 0, 650, 600, 550, 550, 550, 600, 0, "Online", "ALL", "CUET for UG. JNUEE for PG.")
    add("Jamia Millia 2026", "Jamia Millia Islamia entrance.", "Arts", 10, 45, 85, "https://jmi.ac.in", 0, 0, "ALL", "12th", 0, 0, 600, 600, 300, 300, 300, 600, 0, "Online", "ALL", "12th for UG.")
    add("AMU Entrance 2026", "Aligarh Muslim University.", "Arts", 10, 45, 85, "https://amucontrollerexams.com", 0, 0, "ALL", "12th", 0, 0, 600, 600, 300, 300, 300, 600, 0, "Online", "ALL", "12th for UG.")
    add("Symbiosis SET 2026", "Symbiosis Entrance Test.", "Arts", 5, 35, 65, "https://set-test.org", 0, 0, "ALL", "12th", 0, 45.0, 1750, 1750, 1750, 1750, 1750, 1750, 0, "Online", "ALL", "12th 45%.")
    add("Christ University 2026", "Christ University entrance test.", "Arts", 5, 35, 65, "https://christuniversity.in", 17, 25, "ALL", "12th", 0, 45.0, 1000, 1000, 1000, 1000, 1000, 1000, 0, "Online", "ALL", "12th 45%.")

    # ══════════════════════════════════════════════════════════════
    # 19. HOSPITALITY
    # ══════════════════════════════════════════════════════════════
    add("NCHM JEE 2026", "National Council Hotel Management JEE.", "Hospitality", 10, 45, 85, "https://nchmct.org", 0, 22, "ALL", "12th", 0, 0, 1000, 1000, 500, 500, 500, 1000, 0, "Online", "ALL", "12th with English. Age max 22.")
    add("IIHM eCHAT 2026", "IIHM Hotel Management entrance.", "Hospitality", 5, 35, 65, "https://iihm.ac.in", 17, 22, "ALL", "12th", 0, 0, 1000, 1000, 1000, 1000, 1000, 1000, 0, "Online", "ALL", "12th pass.")
    add("WGU Hotel Management 2026", "Welcome Group Graduate School of Hotel.", "Hospitality", 5, 35, 65, "https://itchotels.com/wgsha", 17, 22, "ALL", "12th", 0, 45.0, 1500, 1500, 1500, 1500, 1500, 1500, 0, "Online", "ALL", "12th 45%.")

    # ══════════════════════════════════════════════════════════════
    # 20. AVIATION
    # ══════════════════════════════════════════════════════════════
    add("DGCA CPL 2026", "DGCA Commercial Pilot Licence.", "Aviation", 5, 35, 65, "https://dgca.gov.in", 17, 0, '["PCM"]', "12th", 50.0, 50.0, 2000, 2000, 2000, 2000, 2000, 2000, 0, "Online", "ALL", "12th PCM 50%.")
    add("IndiGo Cadet Pilot 2026", "IndiGo Cadet Pilot Program.", "Aviation", 10, 50, 95, "https://goindigo.in", 17, 26, '["PCM"]', "12th", 55.0, 55.0, 5000, 5000, 5000, 5000, 5000, 5000, 0, "Online", "ALL", "12th PCM 55%. Age 17-26.")
    add("Air India Cabin Crew 2026", "Air India Cabin Crew recruitment.", "Aviation", 5, 35, 65, "https://airindia.in", 18, 27, "ALL", "12th", 0, 0, 0, 0, 0, 0, 0, 0, 0, "Online", "Female", "Female. 12th pass. Height 155cm+.")

    # ══════════════════════════════════════════════════════════════
    # 21. SCHOLARSHIPS
    # ══════════════════════════════════════════════════════════════
    add("NSP Scholarship 2026", "National Scholarship Portal - Multiple schemes.", "Arts", 5, 40, 80, "https://scholarships.gov.in", 0, 0, "ALL", "10th", 0, 0, 0, 0, 0, 0, 0, 0, 0, "Online", "ALL", "Various income/category criteria.")
    add("INSPIRE Scholarship 2026", "DST INSPIRE for Science top students.", "Science", 5, 40, 80, "https://online-inspire.gov.in", 17, 22, '["PCM","PCB"]', "12th", 80.0, 0, 0, 0, 0, 0, 0, 0, 0, "Online", "ALL", "Top 1% in 12th Board.")
    add("Post Matric SC Scholarship 2026", "SC Post Matric Scholarship by govt.", "Arts", 5, 40, 80, "https://scholarships.gov.in", 0, 0, "ALL", "10th", 0, 0, 0, 0, 0, 0, 0, 0, 0, "Online", "ALL", "SC category. Income below 2.5L.")
    add("OBC Pre Matric Scholarship 2026", "OBC Pre Matric Scholarship.", "Arts", 5, 40, 80, "https://scholarships.gov.in", 0, 0, "ALL", "10th", 0, 0, 0, 0, 0, 0, 0, 0, 0, "Online", "ALL", "OBC category.")
    add("Minority Scholarship 2026", "Pre/Post Matric Minority Scholarship.", "Arts", 5, 40, 80, "https://scholarships.gov.in", 0, 0, "ALL", "10th", 0, 0, 0, 0, 0, 0, 0, 0, 0, "Online", "ALL", "Minority communities.")

    # ══════════════════════════════════════════════════════════════
    # ADMIN ACCOUNT
    # ══════════════════════════════════════════════════════════════
    existing = c.execute(
        "SELECT id FROM users WHERE email=?", (ADMIN_EMAIL,)
    ).fetchone()
    if not existing:
        c.execute(
            "INSERT INTO users(email,password,is_admin) VALUES(?,?,1)",
            (ADMIN_EMAIL, generate_password_hash(admin_password))
        )
        aid = c.lastrowid
        c.execute("""INSERT INTO profiles
                     (user_id,full_name,stream,qualification,status)
                     VALUES(?,?,?,?,?)""",
                  (aid, "Admin User", "ALL", "PG", "Passout"))
        print(f"✅ Admin account initialized for {ADMIN_EMAIL}")
    else:
        c.execute(
            "UPDATE users SET is_admin=1 WHERE email=?", (ADMIN_EMAIL,)
        )

    conn.commit()
    total = c.execute("SELECT COUNT(*) FROM exams").fetchone()[0]
    conn.close()
    print(f"✅ {total} exams seeded for {date.today()}")


if __name__ == "__main__":
    init_db()