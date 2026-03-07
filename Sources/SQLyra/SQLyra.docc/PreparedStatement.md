# ``SQLyra/PreparedStatement``

## Topics

### Execution

- ``PreparedStatement/execute()``
- ``PreparedStatement/reset()``

### Retrieving Statement SQL

- ``PreparedStatement/sql``
- ``PreparedStatement/normalizedSQL``
- ``PreparedStatement/expandedSQL``

### SQL Parameters

- ``PreparedStatement/parameterCount``
- ``PreparedStatement/parameterName(at:)``
- ``PreparedStatement/parameterIndex(for:)``

### Binding parameters

- ``PreparedStatement/clearBindings()``
- ``PreparedStatement/bind(parameters:)``
- ``PreparedStatement/bind(name:parameter:)``
- ``PreparedStatement/bind(index:parameter:)``
- ``SQLParameter``

### Columns

- ``PreparedStatement/columnCount``
- ``PreparedStatement/columnName(at:)``

### Result values from a Query

- ``PreparedStatement/row()``
- ``PreparedStatement/array(_:)``
- ``PreparedStatement/array(_:using:)``
- ``PreparedStatement/Row``
- ``PreparedStatement/Value``
