The library has been modified at line 47:

## Original

```lua
print(indent(lust.level + 1) .. red .. err .. normal)
```

## Updated

```lua
print(indent(lust.level + 1) .. red .. tostring(err) .. normal)
```
