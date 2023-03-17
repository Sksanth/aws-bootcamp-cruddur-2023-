from datetime import datetime, timedelta, timezone
from opentelemetry import trace
import logging

from lib.db import pool, query_wrap_array

# tracer = trace.get_tracer("home.activities")

class HomeActivities:
  def run(cognito_user_id=None):
    #logger.info("home activities")
    sql = query_wrap_array("""
      SELECT * FROM activities
    """)
    print("SQL--------------")
    print(sql)
    print("SQL--------------")
    with pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(sql)
        # this will return a tuple
        # the first field being the data
        json = cur.fetchone()
    print("-1----")
    print(json[0])
    return json[0]
    return results