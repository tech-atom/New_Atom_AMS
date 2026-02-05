import mysql.connector

conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password="12345",
    database="lms_system"
)

cursor = conn.cursor()

# Deactivate roll_number and any field with SFDV in the label
cursor.execute("UPDATE registration_fields SET is_active = FALSE WHERE field_name = 'roll_number' OR field_label LIKE '%SFDV%'")
conn.commit()

print(f"Deactivated {cursor.rowcount} field(s)")

# Show remaining active fields
cursor.execute("SELECT field_id, field_name, field_label FROM registration_fields WHERE is_active = TRUE ORDER BY field_order")
rows = cursor.fetchall()

print("\nRemaining active fields:")
for row in rows:
    print(f"  - {row[2]} ({row[1]})")

cursor.close()
conn.close()
