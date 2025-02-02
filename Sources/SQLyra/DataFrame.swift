#if canImport(TabularData)

import TabularData
import Foundation

// MARK: - PreparedStatement + DataFrame

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension PreparedStatement {
    /// Creates a new data frame from a prepared statement.
    ///
    /// ```swift
    /// let df = try db.prepare("SELECT * FROM contacts;").dataFrame()
    /// print(df)
    /// ```
    /// ```
    /// ┏━━━┳━━━━━━━┳━━━━━━━━━━┳━━━━━━━━━━┳━━━━━━━━━┓
    /// ┃   ┃ id    ┃ name     ┃ rating   ┃ image   ┃
    /// ┃   ┃ <Int> ┃ <String> ┃ <Double> ┃ <Data>  ┃
    /// ┡━━━╇━━━━━━━╇━━━━━━━━━━╇━━━━━━━━━━╇━━━━━━━━━┩
    /// │ 0 │     5 │ A        │      2,0 │ nil     │
    /// │ 1 │     6 │ B        │      nil │ 3 bytes │
    /// └───┴───────┴──────────┴──────────┴─────────┘
    /// ```
    /// - Parameters:
    ///   - capacity: An integer that represents the number of elements the columns can initially store.
    ///   - transformers: SQLite column value transformers.
    /// - Returns: The data frame that can print a table.
    /// - Throws: ``DatabaseError``
    public func dataFrame(
        capacity: Int = 0,
        transformers: [String: ColumnValueTransformer] = ColumnValueTransformer.defaults
    ) throws -> TabularData.DataFrame {

        let valueTransformers: [ColumnValueTransformer] = (0..<columnCount).map { index in
            columnDeclaration(at: index).flatMap { transformers[$0] } ?? .string
        }
        let columns: [TabularData.AnyColumn] = (0..<columnCount).map { index in
            let name = columnName(at: index) ?? "N/A"
            return valueTransformers[index].column(name, capacity)
        }
        var df = DataFrame(columns: columns)
        var count = 0
        defer { _reset() }
        while let row = try row() {
            df.appendEmptyRow()
            for index in (0..<columnCount) {
                df.rows[count][index] = row[index].flatMap { valueTransformers[index].transform($0) }
            }
            count += 1
        }
        return df
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public struct ColumnValueTransformer: Sendable {
    public static let string = ColumnValueTransformer { $0.string }
    public static let int = ColumnValueTransformer { $0.int }
    public static let double = ColumnValueTransformer { $0.double }
    public static let blob = ColumnValueTransformer { $0.blob }

    public static let defaults: [String: ColumnValueTransformer] = [
        "INT": .int,
        "INTEGER": .int,
        "NUM": .double,
        "REAL": .double,
        "FLOAT": .double,
        "TEXT": .string,
        "BLOB": .blob,
    ]

    @usableFromInline
    let column: @Sendable (_ name: String, _ capacity: Int) -> AnyColumn
    @usableFromInline
    let transform: @Sendable (PreparedStatement.Value) -> Any?

    @inlinable
    public init<T>(transform: @escaping @Sendable (PreparedStatement.Value) -> T?) {
        self.column = { name, capacity in
            TabularData.Column<T>(name: name, capacity: capacity).eraseToAnyColumn()
        }
        self.transform = transform
    }
}

#endif  // TabularData
