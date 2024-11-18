# streamlit_app.py (Streamlit Frontend)
import streamlit as st
import requests
import pandas as pd
import mysql.connector

API_URL = "http://localhost:5000/api"

def load_customers():
    response = requests.get(f"{API_URL}/customers")
    return response.json()

def load_restaurants():
    response = requests.get(f"{API_URL}/restaurants")
    return response.json()

def check_can_review(customer_id, restaurant_id):
    response = requests.get(
        f"{API_URL}/check-order",
        params={"customer_id": customer_id, "restaurant_id": restaurant_id}
    )
    return response.json()["can_review"]

def submit_review(review_data):
    response = requests.post(f"{API_URL}/submit-review", json=review_data)
    return response.json()

def main():
    st.title("FreshBite Review System")
    
    # Initialize session state for success message
    if 'success_message' not in st.session_state:
        st.session_state.success_message = None
    
    # Load customers and restaurants
    customers = load_customers()
    restaurants = load_restaurants()
    
    # Create selection boxes
    customer_dict = {c['name']: c['customer_id'] for c in customers}
    restaurant_dict = {r['name']: r['restaurant_id'] for r in restaurants}
    
    selected_customer = st.selectbox(
        "Select Customer",
        options=customer_dict.keys(),
        key='customer'
    )
    
    selected_restaurant = st.selectbox(
        "Select Restaurant",
        options=restaurant_dict.keys(),
        key='restaurant'
    )
    
    # Only show the review form if customer has a delivered order
    customer_id = customer_dict[selected_customer]
    restaurant_id = restaurant_dict[selected_restaurant]
    
    # can_review = check_can_review(customer_id, restaurant_id)
    
    # if not can_review:
    #     st.warning("You can only submit reviews for restaurants where you have completed orders.")
    # else:
    with st.form("review_form"):
        rating = st.slider("Rating", 1, 5, 5)
        review_text = st.text_area("Review")
        
        submitted = st.form_submit_button("Submit Review")
        
        if submitted:
            review_data = {
                "customer_id": customer_id,
                "restaurant_id": restaurant_id,
                "rating": rating,
                "review_text": review_text
            }
            
            response = submit_review(review_data)
            
            if "error" in response:
                st.error(response["error"])
            else:
                st.success("Review submitted successfully!")
                    
    # Display existing reviews
    st.subheader("Existing Reviews")
    
    if st.button("Refresh Reviews"):
        conn = mysql.connector.connect(
            host="localhost",
            user="your_username",
            password="your_password",
            database="freshbite"
        )
        
        query = """
        SELECT 
            c.name as customer_name,
            r.name as restaurant_name,
            rev.rating,
            rev.review_text,
            rev.review_time
        FROM review rev
        JOIN customer c ON rev.customer_id = c.customer_id
        JOIN restaurant r ON rev.restaurant_id = r.restaurant_id
        ORDER BY rev.review_time DESC
        """
        
        df = pd.read_sql(query, conn)
        conn.close()
        
        st.dataframe(df)

if __name__ == "__main__":
    main()