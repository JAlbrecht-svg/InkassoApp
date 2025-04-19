//
//  Dateformatting.swift
//  InkassoApp
//
//  Created by Jannick Niwat Siewert-Albrecht on 4/19/25.
//


import Foundation

// Globale Funktionen oder Extension für Datumsformatierung

/// Formatiert einen ISO8601-ähnlichen String in ein lesbares Datums-/Zeitformat.
func formattedDate(_ dateString: String) -> String {
	let formatters = [
		ISO8601DateFormatter(), // Standard ISO8601
		iso8601FractionalSecondsFormatter(), // Mit Millisekunden
        iso8601TimeZoneFormatter() // Mit Zeitzonen-Separator
	]

	for formatter in formatters {
		if let date = formatter.date(from: dateString) {
			// Verwende das Standard .formatted() für lokale Darstellung
			return date.formatted(date: .numeric, time: .shortened) // z.B. 19.04.25, 16:30
		}
	}
	// Fallback, wenn kein Format passt
	return dateString
}

/// Formatiert einen optionalen ISO8601-ähnlichen String.
func formattedDateOptional(_ dateString: String?) -> String {
	guard let dateString = dateString, !dateString.isEmpty else { return "-" }
	return formattedDate(dateString)
}


// Private Helfer-Formatter für spezifische ISO-Varianten
private func iso8601FractionalSecondsFormatter() -> ISO8601DateFormatter {
	let formatter = ISO8601DateFormatter()
	formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
	return formatter
}
private func iso8601TimeZoneFormatter() -> ISO8601DateFormatter {
	let formatter = ISO8601DateFormatter()
	formatter.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]
	return formatter
}

// Alternativ als Date Extension:
/*
extension Date {
    func formattedShort() -> String {
        self.formatted(date: .numeric, time: .shortened)
    }
}

extension String {
    func formattedDateString() -> String {
       // ... (Logik von oben hier rein) ...
        if let date = ... { return date.formattedShort() }
       // ...
       return self
    }
}
*/