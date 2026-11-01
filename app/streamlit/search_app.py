"""
Snowpark Python application demonstrating SQL-native CORTEX_SEARCH_RETRIEVE with freshness re-join and AI_COMPLETE.
"""

from snowflake.snowpark.context import get_active_session

def run_search_and_rag(user_query: str, category_filter: str = "ALL", top_k: int = 2):
    session = get_active_session()
    
    filter_clause = ""
    if category_filter != "ALL":
        filter_clause = f", filter => OBJECT_CONSTRUCT('@eq', OBJECT_CONSTRUCT('CATEGORY', '{category_filter}'))"
    
    # 1. Execute SQL-native search query via CORTEX_SEARCH_RETRIEVE with live freshness re-join
    # Over-fetch from search index (top_k * 2) and join live KNOWLEDGE_BASE_ARTICLES on LAST_UPDATED
    sql_search = f"""
    SELECT
        a.ARTICLE_ID,
        a.ARTICLE_TITLE,
        a.CATEGORY,
        a.BODY_TEXT,
        a.LAST_UPDATED,
        cs.METADATA$REQUEST_ID,
        cs.METADATA$ERROR,
        PARSE_JSON(cs.METADATA$RESULT_DETAIL):scores AS SCORES
    FROM TABLE(CORTEX_SEARCH_RETRIEVE(
        service_name => 'RETRIEVE_DEMO_DB.KNOWLEDGE_CORPUS.KNOWLEDGE_BASE_SEARCH_SERVICE',
        query => '{user_query.replace("'", "''")}',
        limit => {top_k * 2}
        {filter_clause}
    )) AS cs
    JOIN KNOWLEDGE_BASE_ARTICLES AS a
        ON a.ARTICLE_ID = cs.ARTICLE_ID
       AND a.LAST_UPDATED = cs.LAST_UPDATED
    WHERE cs.METADATA$ERROR IS NULL
    LIMIT {top_k}
    """
    
    print(f"--- Running Semantic Search with Freshness Verification for: '{user_query}' ---")
    search_df = session.sql(sql_search).to_pandas()
    
    if search_df.empty:
        print("No matching fresh articles found.")
        return
    
    print(f"Found {len(search_df)} matching fresh knowledge base articles:")
    for idx, row in search_df.iterrows():
        print(f"  [{row['ARTICLE_ID']}] {row['ARTICLE_TITLE']} (Category: {row['CATEGORY']})")
        print(f"  Scores: {row['SCORES']}")
    
    # 2. Context bundling and SQL-native RAG generation via AI_COMPLETE
    context_text = "\\n\\n".join(
        [f"[{r['ARTICLE_TITLE']}]: {r['BODY_TEXT']}" for _, r in search_df.iterrows()]
    )
    
    sql_rag = f"""
    SELECT AI_COMPLETE(
        'llama3.1-70b',
        CONCAT(
            'You are an IT support assistant. Answer the user question based strictly on this context:\\n\\nContext:\\n',
            '{context_text.replace("'", "''")}',
            '\\n\\nQuestion: {user_query.replace("'", "''")}\\n\\nAnswer:'
        )
    ) AS ANSWER
    """
    
    print("\n--- Synthesizing RAG Response via Cortex AI_COMPLETE ---")
    answer_df = session.sql(sql_rag).to_pandas()
    print("Answer:")
    print(answer_df["ANSWER"].iloc[0])

if __name__ == "__main__":
    run_search_and_rag("How do I fix Okta SAML login errors?", category_filter="Security", top_k=2)
