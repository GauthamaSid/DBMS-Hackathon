# app.py (Flask Backend)
from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from datetime import datetime

app = Flask(__name__)
CORS(app)

def get_db_connection():
    return mysql.connector.connect(
        host="192.168.81.214",
    user="PES1UG22CS226",
    password="YASG",
    database="fresh_bite" 
    )

@app.route('/api/check-order', methods=['GET'])
def check_order():
    customer_id = request.args.get('customer_id')
    restaurant_id = request.args.get('restaurant_id')
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        cursor.execute("""
            SELECT COUNT(*) as order_count 
            FROM `order` 
            WHERE customer_id = %s 
            AND restaurant_id = %s 
            AND order_status = 'Delivered'
        """, (customer_id, restaurant_id))
        
        result = cursor.fetchone()
        return jsonify({"can_review": result['order_count'] > 0})
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/api/customers', methods=['GET'])
def get_customers():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        cursor.execute("SELECT customer_id, name FROM customer")
        customers = cursor.fetchall()
        return jsonify(customers)
    finally:
        cursor.close()
        conn.close()

@app.route('/api/restaurants', methods=['GET'])
def get_restaurants():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        cursor.execute("SELECT restaurant_id, name FROM restaurant")
        restaurants = cursor.fetchall()
        return jsonify(restaurants)
    finally:
        cursor.close()
        conn.close()

@app.route('/api/submit-review', methods=['POST'])
def submit_review():
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            INSERT INTO review 
            (customer_id, restaurant_id, rating, review_text, review_time) 
            VALUES (%s, %s, %s, %s, %s)
        """, (
            data['customer_id'],
            data['restaurant_id'],
            data['rating'],
            data['review_text'],
            datetime.now()
        ))
        
        conn.commit()
        return jsonify({"message": "Review submitted successfully"})
    
    except mysql.connector.Error as err:
        conn.rollback()
        if err.errno == 1644:  # Custom error number for our trigger
            return jsonify({"error": "Reviews can only be submitted for completed orders"}), 400
        return jsonify({"error": str(err)}), 500
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    app.run(debug=True, port=5000)