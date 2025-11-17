//
//  DateUtils.swift
//  NutriVision AI
//
//  Date formatting and manipulation utilities
//

import Foundation

struct DateUtils {

    // MARK: - Date Formatters

    static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

    static func dateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter
    }

    // MARK: - Common Formats

    static func formatShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func formatMedium(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func formatLong(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - String Conversion

    static func stringToDate(_ string: String, format: String = "yyyy-MM-dd") -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: string)
    }

    static func dateToString(_ date: Date, format: String = "yyyy-MM-dd") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    static func iso8601ToDate(_ string: String) -> Date? {
        return iso8601Formatter.date(from: string)
    }

    static func dateToISO8601(_ date: Date) -> String {
        return iso8601Formatter.string(from: date)
    }

    // MARK: - Relative Dates

    static func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }

    static func isYesterday(_ date: Date) -> Bool {
        return Calendar.current.isDateInYesterday(date)
    }

    static func isTomorrow(_ date: Date) -> Bool {
        return Calendar.current.isDateInTomorrow(date)
    }

    static func isThisWeek(_ date: Date) -> Bool {
        return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }

    static func isThisMonth(_ date: Date) -> Bool {
        return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
    }

    static func isThisYear(_ date: Date) -> Bool {
        return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
    }

    // MARK: - Date Components

    static func component(_ component: Calendar.Component, from date: Date) -> Int {
        return Calendar.current.component(component, from: date)
    }

    static func year(from date: Date) -> Int {
        return component(.year, from: date)
    }

    static func month(from date: Date) -> Int {
        return component(.month, from: date)
    }

    static func day(from date: Date) -> Int {
        return component(.day, from: date)
    }

    static func weekday(from date: Date) -> Int {
        return component(.weekday, from: date)
    }

    static func hour(from date: Date) -> Int {
        return component(.hour, from: date)
    }

    static func minute(from date: Date) -> Int {
        return component(.minute, from: date)
    }

    // MARK: - Date Manipulation

    static func addDays(_ days: Int, to date: Date = Date()) -> Date? {
        return Calendar.current.date(byAdding: .day, value: days, to: date)
    }

    static func addWeeks(_ weeks: Int, to date: Date = Date()) -> Date? {
        return Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: date)
    }

    static func addMonths(_ months: Int, to date: Date = Date()) -> Date? {
        return Calendar.current.date(byAdding: .month, value: months, to: date)
    }

    static func addYears(_ years: Int, to date: Date = Date()) -> Date? {
        return Calendar.current.date(byAdding: .year, value: years, to: date)
    }

    // MARK: - Date Ranges

    static func startOfDay(_ date: Date = Date()) -> Date {
        return Calendar.current.startOfDay(for: date)
    }

    static func endOfDay(_ date: Date = Date()) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay(date))!
    }

    static func startOfWeek(_ date: Date = Date()) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components)!
    }

    static func endOfWeek(_ date: Date = Date()) -> Date {
        return addDays(6, to: startOfWeek(date))!
    }

    static func startOfMonth(_ date: Date = Date()) -> Date {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        return Calendar.current.date(from: components)!
    }

    static func endOfMonth(_ date: Date = Date()) -> Date {
        var components = DateComponents()
        components.month = 1
        components.day = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth(date))!
    }

    // MARK: - Date Comparison

    static func daysBetween(_ start: Date, and end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }

    static func hoursBetween(_ start: Date, and end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour], from: start, to: end)
        return components.hour ?? 0
    }

    static func minutesBetween(_ start: Date, and end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute], from: start, to: end)
        return components.minute ?? 0
    }

    // MARK: - Age Calculation

    static func age(from birthDate: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year ?? 0
    }

    // MARK: - Meal Time Classification

    static func mealTimeOfDay(_ date: Date = Date()) -> MealTimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)

        switch hour {
        case 5..<11:
            return .breakfast
        case 11..<15:
            return .lunch
        case 15..<18:
            return .snack
        case 18..<23:
            return .dinner
        default:
            return .lateNight
        }
    }

    enum MealTimeOfDay: String {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case snack = "Snack"
        case dinner = "Dinner"
        case lateNight = "Late Night"
    }
}
