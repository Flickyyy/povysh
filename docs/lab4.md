# Лабораторная работа №4 — Загрузка данных в Хранилище

## Цель
Реализовать процедуру, которая загружает данные из филиальных баз (`west_branch`, `east_branch`) в схему `dwh`, минимизируя нагрузку на источники и обеспечивая идемпотентность.

## Основные артефакты
- `lab4-create.sql` — расширение `dblink`, служебная схема `etl`, таблица конфигурации филиалов и процедура `etl.load_from_branches`.
- `lab4-run.sql` — вызов процедуры из базы `dwh`.

## Конфигурация филиалов
Таблица `etl.branch_config` хранит имя филиала из измерения `dim_branch`, имя базы-источника и числовой код филиала. Код используется для построения «натуральных» идентификаторов:
- `source_customer_id = branch_code * 1000 + customerid`
- `source_product_id = branch_code * 1000 + productid`
- `source_deal_id = branch_code * 100000 + dealid`
- `source_deal_product_id = branch_code * 1000000 + dealid * 100 + productid`

## Логика процедуры
Для каждого филиала по конфигурации выполняются шаги:
1. `dblink_connect` в исходную базу и вставка строки в `dim_branch` (если не было).
2. Загрузка измерений `dim_customer`, `dim_product`, `dim_category` с `ON CONFLICT` по натуральным ключам.
3. Обновление связей `dim_product_category` через внутренние surrogate-ключи (`product_key`, `category_key`).
4. Загрузка фактов: выбираются продажи `deal + dealproduct`, рассчитываются surrogate-ключи через существующие измерения, исключаются уже загруженные строки по `source_deal_product_id`.
5. Для новых продаж генерируется запись в `dwh.receipt` на основе даты сделки.

Все операции выполняются в одной процедуре, поэтому повторный вызов не создаёт дубликатов.

## Как запускать
```sql
\connect dwh
\i /workspace/lab4-create.sql
\i /workspace/lab4-run.sql
```
После выполнения в факте `dwh.fact_sale` появляются все продажи из обоих филиалов, а агрегации в `dm` можно пересчитать запуском `lab3-insert.sql`.

## Проверка
- Сравнить количество сделок на источнике и в `dwh.fact_sale` (`COUNT(DISTINCT source_deal_id)`).
- Убедиться, что повторный вызов `CALL etl.load_from_branches();` не добавляет строк.
- Убедиться, что витрина `dm.fact_weekly_sales` пересчитывается из обновлённого факта.

## Пример инкремента
1. Подключиться к филиалу, например, `west_branch` и вставить новую сделку:
	```sql
	\connect west_branch
	INSERT INTO Deal (CustomerID, TotalAmount, DealDate)
	VALUES (5, 0, '2024-02-21') RETURNING DealID;
	-- предположим, вернулся DealID = 26
	INSERT INTO DealProduct (DealID, ProductID, Quantity, Price)
	VALUES (80, 1, 1, 15.00);
	UPDATE Deal SET TotalAmount = 15.00 WHERE DealID = 80;
	```
2. Вернуться в `dwh` и вызвать процедуру:
	```sql
	\connect dwh
	CALL etl.load_from_branches();
	```
3. Проверить, что новая строка появилась в факте и в чеке:
	```sql
	SELECT full_date, branch_name, quantity, unit_price
	FROM dwh.fact_sale fs
	JOIN dwh.dim_date dd ON dd.date_key = fs.date_key
	JOIN dwh.dim_branch db ON db.branch_key = fs.branch_key
	WHERE source_deal_id = 100000 + 27; -- формула branch_code * 100000 + dealid

	SELECT COUNT(*) FROM dwh.receipt WHERE sale_key =
	  (SELECT sale_key FROM dwh.fact_sale WHERE source_deal_id = 100000 + 26);
	```

## Мини-пример «вставил → мигрировал → проверил»
```bash
# 1. Добавляем сделку A в west_branch (дата должна попадать в календарь dim_date)
docker exec -it dwh-postgres psql -U postgres -d west_branch \
	-c "INSERT INTO Deal (CustomerID, TotalAmount, DealDate) VALUES (6, 0, '2024-02-20') RETURNING DealID;"
# Запоминаем напечатанный DealID и подставляем его в следующую команду вместо <A_ID>
docker exec -it dwh-postgres psql -U postgres -d west_branch \
	-c "INSERT INTO DealProduct (DealID, ProductID, Quantity, Price) VALUES (<A_ID>, 6, 1, 18.90); UPDATE Deal SET TotalAmount = 18.90 WHERE DealID = <A_ID>;"
docker exec -it dwh-postgres psql -U postgres -d dwh -c "CALL etl.load_from_branches();"
docker exec -it dwh-postgres psql -U postgres -d dwh \
	-c "SELECT source_deal_id, quantity, unit_price FROM dwh.fact_sale WHERE source_deal_id = 100000 + <A_ID>;"

# 2. Удаляем сделку A, добавляем сделку B и снова переносим
docker exec -it dwh-postgres psql -U postgres -d west_branch \
	-c "DELETE FROM DealProduct WHERE DealID = <A_ID>; DELETE FROM Deal WHERE DealID = <A_ID>;"
docker exec -it dwh-postgres psql -U postgres -d west_branch \
	-c "INSERT INTO Deal (CustomerID, TotalAmount, DealDate) VALUES (7, 0, '2024-02-22') RETURNING DealID;"
# Подставляем новый DealID вместо <B_ID>
docker exec -it dwh-postgres psql -U postgres -d west_branch \
	-c "INSERT INTO DealProduct (DealID, ProductID, Quantity, Price) VALUES (<B_ID>, 7, 2, 20.50); UPDATE Deal SET TotalAmount = 41.00 WHERE DealID = <B_ID>;"
docker exec -it dwh-postgres psql -U postgres -d dwh -c "CALL etl.load_from_branches();"
docker exec -it dwh-postgres psql -U postgres -d dwh \
	-c "SELECT COUNT(*) FROM dwh.fact_sale WHERE source_deal_id IN (100000 + <A_ID>, 100000 + <B_ID>);"
```
После второго запуска в `dwh.fact_sale` останется строка с `A` (потому что DWH не удаляет историю) и добавится строка с `B` — суммарно станет на одну запись больше.

### Как выполняются требования ЛР4
- **Минимальная нагрузка на источники**: подключение к филиалу происходит один раз на итерацию, извлечение данных идёт простыми SELECT без блокировок.
- **Идемпотентность**: все натуральные ключи загружаются через `ON CONFLICT`, факт — через проверку `NOT EXISTS` и уникальный индекс `source_deal_product_id`. Повторные запуски не создают дубликатов.
- **Связность**: после вставки фактов процедура создаёт чеки и отдельный завершающий блок доначисляет их, если предыдущий запуск прервался.
- **Гибкость**: конфигурация филиалов хранится в `etl.branch_config`, достаточно добавить строку с кодом и именем базы, чтобы процедура начала её обрабатывать.
