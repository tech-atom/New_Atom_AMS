"""
Database Backup Script for ATOM SHAALE AMS
==========================================
This script creates a complete backup of the entire MySQL database
into a single SQL file that can be used to restore the database.

Usage:
    python database_backup.py
    
Output:
    Creates a file: database_backup_YYYYMMDD_HHMMSS.sql
"""

import mysql.connector
import os
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def get_db_connection():
    """Create database connection"""
    try:
        conn = mysql.connector.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            user=os.getenv('DB_USER', 'root'),
            password=os.getenv('DB_PASSWORD', '12345'),
            database=os.getenv('DB_NAME', 'lms_system'),
            charset='utf8mb4',
            use_unicode=True
        )
        return conn
    except Exception as e:
        print(f"❌ Error connecting to database: {e}")
        return None

def get_all_tables(cursor):
    """Get list of all tables in the database"""
    cursor.execute("SHOW TABLES")
    tables = [table[0] for table in cursor.fetchall()]
    return tables

def get_table_create_statement(cursor, table_name):
    """Get CREATE TABLE statement for a table"""
    cursor.execute(f"SHOW CREATE TABLE `{table_name}`")
    return cursor.fetchone()[1]

def get_table_data(cursor, table_name):
    """Get all data from a table as INSERT statements"""
    cursor.execute(f"SELECT * FROM `{table_name}`")
    rows = cursor.fetchall()
    
    if not rows:
        return []
    
    # Get column information
    cursor.execute(f"DESCRIBE `{table_name}`")
    columns = [col[0] for col in cursor.fetchall()]
    
    insert_statements = []
    for row in rows:
        # Escape and format values
        values = []
        for value in row:
            if value is None:
                values.append('NULL')
            elif isinstance(value, (int, float)):
                values.append(str(value))
            elif isinstance(value, bytes):
                # Handle BLOB/binary data
                values.append(f"0x{value.hex()}")
            elif isinstance(value, datetime):
                values.append(f"'{value.strftime('%Y-%m-%d %H:%M:%S')}'")
            else:
                # Escape single quotes in strings
                escaped = str(value).replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n').replace('\r', '\\r')
                values.append(f"'{escaped}'")
        
        column_names = ', '.join([f"`{col}`" for col in columns])
        values_str = ', '.join(values)
        insert_statements.append(f"INSERT INTO `{table_name}` ({column_names}) VALUES ({values_str});")
    
    return insert_statements

def create_database_backup():
    """Create complete database backup"""
    print("=" * 80)
    print("🔄 ATOM SHAALE AMS - DATABASE BACKUP UTILITY")
    print("=" * 80)
    
    # Create connection
    conn = get_db_connection()
    if not conn:
        return False
    
    cursor = conn.cursor()
    
    # Get database name
    db_name = os.getenv('DB_NAME', 'lms_system')
    
    # Create backup filename with timestamp
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_filename = f"database_backup_{timestamp}.sql"
    
    print(f"\n📦 Creating backup file: {backup_filename}")
    print(f"📊 Database: {db_name}")
    
    try:
        with open(backup_filename, 'w', encoding='utf-8') as f:
            # Write header
            f.write("-- ======================================================================\n")
            f.write(f"-- ATOM SHAALE AMS - Complete Database Backup\n")
            f.write(f"-- Database: {db_name}\n")
            f.write(f"-- Created: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("-- ======================================================================\n\n")
            
            # Disable foreign key checks and other settings for import
            f.write("SET FOREIGN_KEY_CHECKS=0;\n")
            f.write("SET SQL_MODE='NO_AUTO_VALUE_ON_ZERO';\n")
            f.write("SET AUTOCOMMIT=0;\n")
            f.write("START TRANSACTION;\n")
            f.write("SET time_zone = '+00:00';\n\n")
            
            # Get all tables
            tables = get_all_tables(cursor)
            print(f"\n📋 Found {len(tables)} tables to backup:\n")
            
            total_rows = 0
            
            for i, table in enumerate(tables, 1):
                print(f"   [{i}/{len(tables)}] Backing up table: {table}...", end=" ")
                
                # Write table structure
                f.write(f"\n-- --------------------------------------------------------\n")
                f.write(f"-- Table structure for table `{table}`\n")
                f.write(f"-- --------------------------------------------------------\n\n")
                
                # Drop table if exists
                f.write(f"DROP TABLE IF EXISTS `{table}`;\n\n")
                
                # Create table statement
                create_stmt = get_table_create_statement(cursor, table)
                f.write(f"{create_stmt};\n\n")
                
                # Write table data
                f.write(f"-- Dumping data for table `{table}`\n\n")
                insert_statements = get_table_data(cursor, table)
                
                if insert_statements:
                    f.write(f"LOCK TABLES `{table}` WRITE;\n")
                    for stmt in insert_statements:
                        f.write(f"{stmt}\n")
                    f.write(f"UNLOCK TABLES;\n\n")
                    print(f"✅ {len(insert_statements)} rows")
                    total_rows += len(insert_statements)
                else:
                    print("✅ (empty)")
                
            # Re-enable foreign key checks
            f.write("\n-- --------------------------------------------------------\n")
            f.write("-- Finalizing backup\n")
            f.write("-- --------------------------------------------------------\n\n")
            f.write("COMMIT;\n")
            f.write("SET FOREIGN_KEY_CHECKS=1;\n")
            
        # Get file size
        file_size = os.path.getsize(backup_filename)
        file_size_mb = file_size / (1024 * 1024)
        
        print("\n" + "=" * 80)
        print("✅ BACKUP COMPLETED SUCCESSFULLY!")
        print("=" * 80)
        print(f"\n📄 Backup file: {backup_filename}")
        print(f"📊 Total tables: {len(tables)}")
        print(f"📈 Total rows: {total_rows}")
        print(f"💾 File size: {file_size_mb:.2f} MB ({file_size:,} bytes)")
        print(f"\n📍 Location: {os.path.abspath(backup_filename)}")
        print("\n" + "=" * 80)
        
        return True
        
    except Exception as e:
        print(f"\n❌ Error creating backup: {e}")
        return False
    
    finally:
        cursor.close()
        conn.close()

def restore_database(backup_file):
    """
    Restore database from backup file
    WARNING: This will overwrite existing data!
    """
    print("=" * 80)
    print("⚠️  DATABASE RESTORE UTILITY")
    print("=" * 80)
    
    if not os.path.exists(backup_file):
        print(f"❌ Backup file not found: {backup_file}")
        return False
    
    print(f"\n⚠️  WARNING: This will OVERWRITE your current database!")
    print(f"📄 Backup file: {backup_file}")
    
    response = input("\nType 'YES' to confirm restore: ")
    if response != 'YES':
        print("❌ Restore cancelled.")
        return False
    
    conn = get_db_connection()
    if not conn:
        return False
    
    cursor = conn.cursor()
    
    try:
        print("\n🔄 Reading backup file...")
        with open(backup_file, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        print("🔄 Restoring database...")
        
        # Split into individual statements and execute
        statements = sql_content.split(';\n')
        total = len(statements)
        
        for i, statement in enumerate(statements, 1):
            if statement.strip():
                if i % 100 == 0:
                    print(f"   Progress: {i}/{total} statements...", end='\r')
                cursor.execute(statement)
        
        conn.commit()
        
        print("\n\n✅ DATABASE RESTORED SUCCESSFULLY!")
        print("=" * 80)
        
        return True
        
    except Exception as e:
        print(f"\n❌ Error restoring database: {e}")
        conn.rollback()
        return False
    
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    import sys
    
    print("\n")
    
    if len(sys.argv) > 1:
        if sys.argv[1] == '--restore' and len(sys.argv) > 2:
            # Restore mode
            restore_database(sys.argv[2])
        else:
            print("Usage:")
            print("  python database_backup.py                    # Create backup")
            print("  python database_backup.py --restore <file>   # Restore from backup")
    else:
        # Backup mode (default)
        create_database_backup()
    
    print("\n")
