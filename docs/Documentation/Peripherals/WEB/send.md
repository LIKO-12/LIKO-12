# WEB.send
---

Send a request to a URL.

---

* **Available since:** _WEB:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _WEB:_ v1.0.0, _LIKO-12_: v0.6.0

---

```lua
local requestID = WEB.send(url, args)
```

---
### Arguments
---

* **url (string):** URL to send request to.
* **args (table, nil) (Default:`"nil"`):** Arguements to send in the request.


---
### Returns
---

* **requestID (number):** The request's id, used to read it later.

