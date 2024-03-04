--
-- Table: users
--
INSERT INTO users VALUES (1, 'test_user', 'test_firstname', 'test_middlename', 'test_lastname', 'test@mail.ru');

--
-- Table: categories
--
INSERT INTO categories VALUES (1, 'category1');
INSERT INTO categories VALUES (2, 'category2');

--
-- Table: articles
--
INSERT INTO articles(article_id, article_text, fk_user_id, fk_category_id) VALUES (1, 'test_text', 1, 1);
INSERT INTO articles(article_id, article_text, fk_user_id, fk_category_id) VALUES (2, 'test_text2', 1, 2);
INSERT INTO articles(article_id, article_text, fk_user_id, fk_category_id) VALUES (3, 'test_text3', 1, 1);

--
-- Table: articles
--
INSERT INTO comments(comment_id, comment_text, fk_user_id, fk_article_id) VALUES (1, 'test_comment', 1, 1);
INSERT INTO comments(comment_id, comment_text, fk_user_id, fk_article_id) VALUES (2, 'test_comment2', 1, 2);
INSERT INTO comments(comment_id, comment_text, fk_user_id, fk_article_id) VALUES (3, 'test_comment3', 1, 3);
INSERT INTO comments(comment_id, comment_text, fk_user_id, fk_article_id) VALUES (4, 'test_comment4', 1, 1);