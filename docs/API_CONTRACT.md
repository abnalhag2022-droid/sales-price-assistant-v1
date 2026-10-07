# API Contract — Mobile V1

المسارات التي يعتمد عليها تطبيق الهاتف:

- `GET /api/health`
- `POST /api/auth/login` → `{access_token, user:{username,display_name,role}}`
- `GET /api/items?q=`
- `GET /api/customers`
- `GET /api/price-lists`
- `GET /api/users` (admin)
- `POST /api/sessions`
- `POST /api/sessions/{session_id}/items` مع `X-Idempotency-Key`
- `PUT /api/sessions/{session_id}/items/{item_code}` مع `X-Idempotency-Key`
- `DELETE /api/sessions/{session_id}/items/{item_code}`
- `POST /api/sessions/{session_id}/complete`
- `GET /api/sales/history?item_code=`
- `POST/PUT/DELETE /api/items/...`
- `POST/PUT/DELETE /api/customers/...`
- `POST/PUT/DELETE /api/price-lists/...`

## Idempotency
كل إضافة سطر من الهاتف تولد `operationId` واحدًا، وتعيد استخدامه عند التحول إلى Offline ثم المزامنة. هذا يمنع تكرار السطر عند إعادة إرسال نفس العملية.

## Offline
التطبيق يحفظ المعاملات والطابور محليًا. عند عودة الاتصال ينفذ العمليات بالترتيب، ثم يمسح الطابور بعد نجاحها.
