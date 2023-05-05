//
//  File.swift
//  Kitty
//
//  Created by Dinh Van Hoang on 18/04/2023.
//

import Foundation


protocol MonthlyStatisticProtocol {
    var monthlyHistory: MonthlyHistory? { get set }
    var refreshData: (()-> ())? { get set }
    func loadApi()
}
class HomeViewModel :MonthlyStatisticProtocol{
    let storageService: MoneyStorageProtocol
    var monthlyHistory: MonthlyHistory?
    
    
    var refreshData: (() -> ())?
    init(service: MoneyStorageProtocol = StorageService.init()) {
        self.storageService = service
        self.loadApi()
    }
  
    
    
    
    func loadApi() {
        var monthlyExpense: Double = 0.0
        var monthlyIncome: Double = 0.0
        var monthlyBalance: Double = 0.0
        var listMonthlyHistory:[Money]? = []
        var listMonthlyExpense:[Money]? = []
        var listDailyExpenseHistory:[DailyExpenseHistory]? = []
        let filterDate = Date().toString(pattern: "MM-YYYY")
        
        
//        DataManager.instance.save()
        storageService.fetchMoney {
            listMoney in
            /// Query table Money key : Month - Year
            listMonthlyHistory = listMoney?.filter({ money in
                return (money.createAt?.contains(filterDate) ?? false)
            })
            /// Query Data Money Type
            listMonthlyHistory?.forEach({ moneyElement in
                if(moneyElement.type == MoneyEnum.expense){
                    monthlyExpense += ( moneyElement.value ?? 0 )
                    listMonthlyExpense?.append(moneyElement)
                } else if(moneyElement.type == MoneyEnum.income)
                {
                    monthlyIncome +=  (moneyElement.value ?? 0)
                }
            })
            monthlyBalance = monthlyIncome - monthlyExpense
        }
        
        
        /// Create Dictionary to Group by createAt
        let dictionary = Dictionary(grouping: listMonthlyExpense ?? [], by: { $0.createAt })
//        print("dictionary \(dictionary)")
        /// Convert Dictionary To Array
        dictionary.forEach { (key: String?, value: [Money]) in
            listDailyExpenseHistory?.append(DailyExpenseHistory(dayId: key, expenses: value))
        }
//        print("listDailyExpenseHistory \(listDailyExpenseHistory)")
        
        monthlyHistory = MonthlyHistory(monthlyExpense: monthlyExpense, monthlyIncome: monthlyIncome, monthlyBalance: monthlyBalance,listDailyExpenseHistory: listDailyExpenseHistory)
    }
}
