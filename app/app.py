import os
from flask import Flask, jsonify
import psycopg2

app = Flask(__name__)

def get_db():
    return psycopg2.connect(
        host=os.environ.get("POSTGRES_HOST"),
        port=os.environ.get("POSTGRES_PORT", "5432"),
        user=os.environ.get("POSTGRES_USER"),
        password=os.environ.get("POSTGRES_PASSWORD"),
        dbname=os.environ.get("POSTGRES_DB"),
    )


@app.route("/")
def home():
    return "App is running"


@app.route("/health")
def health():
    return "ok"


@app.route("/ready")
def ready():
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT 1")
        cur.close()
        conn.close()
        return "ready"
    except Exception as e:
        return str(e), 503

@app.route("/items", methods=["GET"])
def list_items():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS items (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT NOW()
        )
    """)
    conn.commit()
    cur.execute("SELECT id, name, created_at FROM items ORDER BY id")
    items = [{"id": r[0], "name": r[1], "created_at": str(r[2])} for r in cur.fetchall()]
    cur.close()
    conn.close()
    return jsonify(items)


@app.route("/items", methods=["POST"])
def create_item():
    from flask import request
    data = request.get_json()
    if not data or "name" not in data:
        return jsonify({"error": "name is required"}), 400

    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS items (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT NOW()
        )
    """)
    cur.execute("INSERT INTO items (name) VALUES (%s) RETURNING id, name, created_at", (data["name"],))
    row = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"id": row[0], "name": row[1], "created_at": str(row[2])}), 201
