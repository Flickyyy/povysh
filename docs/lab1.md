# Lab 1 – Branch Source Databases

## Purpose
Прототип БД филиала для накопления первичных продаж. База повторяется для «Филиал Запад» и «Филиал Восток».

## Скрипты
- `lab1-create.sql` — создаёт схему филиала (основные таблицы, внешние ключи, расширение `pgcrypto` для генерации `RowGuid`).
- `lab1-insert.sql` — наполняет каждый филиал 25 клиентами, 25 товарами, 8 категориями, 25 сделками и 50 строками в мостах `ProductCategory`/`DealProduct`. Скрипт сначала очищает таблицы, затем заново вставляет демо-данные.

## Что показать на защите
1. Запуск `docker compose up` и проверка, что базы `west_branch` и `east_branch` содержат требуемый объём данных (`SELECT COUNT(*) FROM Deal` выдаёт 25, `SELECT COUNT(*) FROM DealProduct` выдаёт 50).
2. Показать, что суммы сделок совпадают с суммой позиций (`SELECT DealID, TotalAmount, SUM(Quantity * Price) FROM DealProduct JOIN Deal USING (DealID) GROUP BY DealID, TotalAmount`).
