import sqlite3

conn = sqlite3.connect('amphitheater_local.db')
cur = conn.cursor()

cur.execute('DELETE FROM reservations')
cur.execute('DELETE FROM active_reservation_slots')
cur.execute('DELETE FROM audit_logs')
cur.execute('DELETE FROM login_attempts')
cur.execute('DELETE FROM refresh_sessions')
cur.execute("DELETE FROM users WHERE username NOT IN ('123IMHModirkol@1090', 'test')")

conn.commit()
print("Remaining users:", cur.execute("SELECT id, username, role FROM users").fetchall())
print("Remaining reservations:", cur.execute("SELECT COUNT(*) FROM reservations").fetchone()[0])
conn.close()
