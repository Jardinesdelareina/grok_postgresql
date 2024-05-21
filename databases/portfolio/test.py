from db import create_query

'''
query = create_query("SELECT * FROM ms.get_portfolios(1)")
for row in query:
    title, is_published = row
    print(title, is_published)
'''


query = create_query("SELECT * FROM ms.get_total_balance_user(1)")
for row in query:
    print(row[0])
