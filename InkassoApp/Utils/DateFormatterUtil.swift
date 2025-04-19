import Foundation

// --- Datumsformatierung ---

/// Formatiert einen ISO8601-ähnlichen String in ein lesbares Datums-/Zeitformat (lokalisiert).
func formattedDate(_ dateString: String) -> String {
    let formatters = [
        ISO8601DateFormatter(), // Standard ISO8601
        iso8601FractionalSecondsFormatter(), // Mit Millisekunden
        iso8601TimeZoneFormatter(), // Mit Zeitzonen-Separator Z
        iso8601DateOnlyFormatter() // Nur Datum
    ]

    for formatter in formatters {
        if let date = formatter.date(from: dateString) {
            // Verwende das Standard .formatted() für lokale Darstellung
            return date.formatted(.dateTime.day().month().year().hour().minute())
        }
    }
    // Fallback
    return dateString
}

/// Formatiert einen optionalen ISO8601-ähnlichen String. Gibt "-" zurück, wenn nil oder leer.
func formattedDateOptional(_ dateString: String?) -> String {
    guard let dateString = dateString, !dateString.isEmpty else { return "-" }
    return formattedDate(dateString)
}

// --- Private Helfer-Formatter (Nur einmal definiert!) ---
private func iso8601FractionalSecondsFormatter() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}
private func iso8601TimeZoneFormatter() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime, .withColonSeparatorInTimeZone]
    return formatter
}
 private func iso8601DateOnlyFormatter() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
    return formatter
}
// --- Ende Private Helfer ---


// --- String Extension (wie zuvor) ---
extension String {
    var displayFormat: String {
        self.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
// --- ENDE String Extension ---
