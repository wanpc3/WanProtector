# WanProtector - Password Manager Application
**Developer:** ILHAN IDRISS

**Platform:** Android

# What is WanProtector?
WanProtector is a standalone password manager app designed to securely store sensitive information such as username and password in an encrypted vault. It helps you manage your credentials safely and conveniently.

# Database (Vault) Structure
In WanProtector, the database acts as your personal vault — just like how people store money, gold, or jewellery in a safe, this vault stores your most valuable digital assets: your credentials.

**1. Master Password Table**

Holds the single password that unlocks the vault. Without it, all stored data is inaccessible.
```sql
master_password
---------------
id            INTEGER PRIMARY KEY
password      TEXT    NOT NULL
created_at    TEXT    NOT NULL DEFAULT (timestamp)
last_updated  TEXT    NOT NULL DEFAULT (timestamp)
```

**2. Entry Table**

Stores each saved credential (username, password, notes, etc.).
```sql
entry
-----
id            INTEGER PRIMARY KEY
title         TEXT    NOT NULL
username      TEXT    NOT NULL
password      TEXT
url           TEXT
notes         TEXT
created_at    TEXT    NOT NULL DEFAULT (timestamp)
last_updated  TEXT    NOT NULL DEFAULT (timestamp)
```

**3. Deleted Entry Table**

Keeps records of deleted entries for recovery purposes.
```sql
deleted_entry
-------------
deleted_id    INTEGER PRIMARY KEY
title         TEXT    NOT NULL
username      TEXT    NOT NULL
password      TEXT
url           TEXT
notes         TEXT
created_at    TEXT    NOT NULL DEFAULT (timestamp)
last_updated  TEXT    NOT NULL DEFAULT (timestamp)
```

> **💡 Note**  
> - All dates (`created_at`, `last_updated`) are stored as **timestamps**.  
> - Data in all tables is encrypted using **AES-256** before storage.

# How does WanProtector work?
To access the vault, users must create a **master password**—a unique key that protects all stored entries. Without this master password, access to the vault is permanently lost, ensuring that your data remains secure even if your device falls into the wrong hands.

Once inside the vault, users can create and manage entries—each containing essential information like usernames and passwords. These entries are always accessible to the user, especially when a password is forgotten.

# Does WanProtector requires an Internet connection?
Not at all. This app is **100% offline by default** — unless you choose to back up your vault to a cloud provider like Google Drive, which does require an internet connection.

# Why choose WanProtector?
WanProtector is designed to be both **user-friendly** and **secure**, offering a range of features to enhance your password management experience.

# Key Features
🔐 **Encrypted Vault** – All data is securely stored using strong encryption (AES-256).

📥 **Backup / Restore** – Safely back up your vault and restore it when needed.

🔑 **Password Generator** – Create strong, random passwords in seconds.

🗑️ **Delete & Restore** – Easily delete passwords and restore them when needed.

⏱️ **Auto-Lock** – Automatically locks the app after 1 minute of inactivity or when the screen turns off.
