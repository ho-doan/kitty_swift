//
//  File.swift
//  Kitty
//
//  Created by Dinh Van Hoang on 18/04/2023.
//

import Foundation

protocol MonthlyStatisticProtocol {
    
    func getCurrentFilterDate()
    var didLoadDataSuccess: ((MonthlyHistory) -> Void)? {get set}
    var didloadDataFailed: ((Error) -> Void)? {get set}
    
}

protocol MonthPickerProtocol {
    var currentFilterDate: Date? { get set }
    func setCurrentFilterDate(filterDate: Date?)
}

class HomeViewModel: MonthlyStatisticProtocol, MonthPickerProtocol {
    
    // MARK: - Properties
    var didLoadDataSuccess: ((MonthlyHistory) -> Void)?
    var didloadDataFailed: ((Error) -> Void)?
    let storageService: MoneyStorageProtocol
    var currentFilterDate: Date?
    
    // MARK: - Contructor
    init(service: MoneyStorageProtocol = StorageService()) {
        self.storageService = service
        self.currentFilterDate = Date()
        NotificationCenterService.addObserver(selector: #selector(onListenUpdateHomeData), key: NotificationEventKey.updateHomeData)
    }
    @objc private func onListenUpdateHomeData(_ notification: Notification) {
        Log.i("notification.object\(notification.object)")
        self.currentFilterDate = notification.object as? Date
        fetchListDataExpense()
    }
    
    // MARK: - Method
    func getCurrentFilterDate() {
        self.currentFilterDate = Date()
        fetchListDataExpense()
    }
    func setCurrentFilterDate(filterDate: Date?) {
        NotificationCenterService.post(key: NotificationEventKey.updateReportData, value: filterDate)
        self.currentFilterDate = filterDate
        fetchListDataExpense()
    }
    func fetchListDataExpense() {
        var monthlyExpense = 0.0
        var monthlyIncome = 0.0
        var monthlyBalance = 0.0
        var listMonthlyHistory: [Money] = []
        var listMonthlyExpense: [Money] = []
        var listDailyExpenseHistory: [DailyExpenseHistory] = []
        guard let filterDate = currentFilterDate?.toString(pattern: StringUtils.numMonthYearPatternDate) else { return }
        storageService.fetchMoney(success: { listMoney in
            listMonthlyHistory = listMoney.filter { money in
                money.createAt?.contains(filterDate) ?? false
            }
            /// Query Data Money Type
            listMonthlyHistory.forEach { moneyElement in
                if moneyElement.type == MoneyEnum.expense {
                    monthlyExpense += (moneyElement.value ?? 0)
                    listMonthlyExpense.append(moneyElement)
                } else if moneyElement.type == MoneyEnum.income {
                    monthlyIncome += (moneyElement.value ?? 0)
                }
            }
            let dictionary = Dictionary(grouping: listMonthlyExpense, by: { $0.createAt })
            /// Convert Dictionary To Array
            dictionary.forEach { (key: String?, value: [Money]) in
                listDailyExpenseHistory.append(DailyExpenseHistory(dayId: key, expenses: value))
            }
            monthlyBalance = monthlyIncome - monthlyExpense
            let monthlyHistory = MonthlyHistory(monthlyExpense: monthlyExpense, monthlyIncome: monthlyIncome, monthlyBalance: monthlyBalance, listDailyExpenseHistory: listDailyExpenseHistory)
            
            self.didLoadDataSuccess?(monthlyHistory)
        }, failure: { error in
            self.didloadDataFailed?(error)
        })
        
    }
}