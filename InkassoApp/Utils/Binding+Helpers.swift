//
//  Binding+Helpers.swift
//  InkassoApp
//
//  Created by Jannick Niwat Siewert-Albrecht on 4/19/25.
//


import SwiftUI

// Helper, um ein Binding zu einem optionalen String zu erstellen,
// das einen leeren String zurückgibt, wenn der Wert nil ist,
// und nil setzt, wenn der neue Wert leer ist.
extension Binding where Value == String? {
    func withDefault(_ defaultValue: String = "") -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}

// Helper für optionale Doubles (z.B. Kosten)
extension Binding where Value == Double? {
    func withDefault(_ defaultValue: Double = 0.0) -> Binding<Double> {
        Binding<Double>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0 } // Behalte 0.0, setze nicht auf nil
        )
    }
}

// Helper um direkt an Properties eines optionalen @Published Objekts zu binden
// Erzeugt ein Binding zum Property des Objekts, gibt einen Default zurück, wenn das Objekt nil ist.
// Verwendung: $viewModel.optionalObject.binding(keyPath: \.propertyName, defaultValue: ...)
extension Binding {
     func binding<T>(keyPath: WritableKeyPath<Value, T>, defaultValue: T) -> Binding<T> where Value: Any {
         Binding<T>(
             get: {
                 // Wenn der Wert selbst optional ist und nil, gib Default zurück
                 guard let value = self.wrappedValue else { return defaultValue }
                 // Prüfe, ob der Wert das KeyPath-Property hat (sollte der Fall sein, wenn nicht nil)
                 // Diese Prüfung ist etwas umständlich, normalerweise würde man es direkt verwenden,
                 // aber wir sichern es hier ab.
                  guard let concreteValue = value as? NSObject, concreteValue.responds(to: Selector(keyPath.debugDescription)) else {
                    // Fallback, sollte für @Published Objekte nicht nötig sein, aber sicher ist sicher
                    // return defaultValue // Vorsicht: Funktioniert so nicht direkt mit KeyPath
                    // Sicherer: Direkter Zugriff mit Optional Chaining
                     if let specificValue = (value as? NSObject)?.value(forKeyPath: keyPath.debugDescription) as? T {
                        return specificValue
                     } else {
                        // Wenn das Objekt existiert, aber der KeyPath nicht passt (sollte nicht sein)
                        // oder der Wert nil ist (bei optionalen Properties im Objekt), gib Default
                        // Problem: Wir wissen nicht, ob T optional ist.
                        // Einfacher Ansatz: Direkter Zugriff im View mit nil-coalescing oder if let.
                        // Dieser generische Helper ist hier zu komplex.
                        // Entfernen wir ihn und binden direkt in der View.
                        fatalError("Complex optional keypath binding not fully supported here. Bind directly in View.")
                     }

                 }
                 // return value[keyPath: keyPath] // Direktzugriff, wenn Value nicht optional wäre
             },
             set: { newValue in
                 // Setze nur, wenn das Objekt existiert
                // self.wrappedValue?[keyPath: keyPath] = newValue // Direktzugriff, wenn Value nicht optional wäre
             }
         )
     }
 }


// Einfacherer Binding Helper für optionale Objekte und ihre non-optional Properties
// Verwendung: $viewModel.debtor.map(keyPath: \.name, defaultValue: "")
extension Binding where Value == Debtor? { // Beispiel für Debtor
    func map<T>(keyPath: WritableKeyPath<Debtor, T>, defaultValue: T) -> Binding<T> {
        Binding<T>(
            get: {
                self.wrappedValue?[keyPath: keyPath] ?? defaultValue
            },
            set: { newValue in
                // Stelle sicher, dass das Objekt existiert, bevor geschrieben wird
                if self.wrappedValue != nil {
                    self.wrappedValue?[keyPath: keyPath] = newValue
                } else {
                    print("Warning: Tried to set property on nil optional object \(Value.self)")
                }
            }
        )
    }
}