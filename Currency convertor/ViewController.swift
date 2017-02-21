//
//  ViewController.swift
//  Currency convertor
//
//  Created by Павел Мартыненков on 20.02.17.
//  Copyright © 2017 Павел Мартыненков. All rights reserved.
//

import UIKit
import SystemConfiguration

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate{

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var pickerFrom: UIPickerView!
    @IBOutlet weak var pickerTo: UIPickerView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var dateString: String?
    
    var currencies = ["EUR", "RUB", "USD"]
    
    var didViewAppear = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.label.text = "Тут будет текст"
        
        self.pickerTo.dataSource = self
        self.pickerFrom.dataSource = self
        
        self.pickerTo.delegate = self
        self.pickerFrom.delegate = self
        
//        self.pickerTo.layer.cornerRadius = 10;
//        self.pickerTo.layer.masksToBounds = true;
//        
//        self.pickerFrom.layer.cornerRadius = 10;
//        self.pickerFrom.layer.masksToBounds = true;
        
        self.activityIndicator.hidesWhenStopped = true
        self.requestCurrentciesList()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.didViewAppear = true
        self.requestCurrentCurrencyRate()
        
    }


    func numberOfComponents(in pickerView: UIPickerView) -> Int{
        
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView === pickerTo {
            return self.currenciesExceptBase().count
        }
        
        return self.currencies.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView === pickerTo {
            return self.currenciesExceptBase()[row]
        }
        
        return currencies[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView === pickerFrom {
            self.pickerTo.reloadAllComponents()
        }
        
        if self.currencies.count <= 3 {
            self.requestCurrentciesList()
        }
        
        if self.didViewAppear {
        self.requestCurrentCurrencyRate()
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: pickerView.frame.size.width, height: 30))
        
            label.backgroundColor = UIColor.white
            label.textColor = UIColor.darkGray
            label.font = UIFont(name: "AppleSDGothicNeo - Bolt", size: 17)
            label.textAlignment = .center
        
            if pickerView === pickerTo {
                label.text = self.currenciesExceptBase()[row]
            } else {
               label.text = self.currencies[row]
            }
        
            return label
        
    }
    
    func requestCurrentCurrencyRate() {
        self.activityIndicator.startAnimating()
        self.label.text = ""
        
        let baseCurrencyIndex = self.pickerFrom.selectedRow(inComponent: 0)
        let toCurrencyIndex = self.pickerTo.selectedRow(inComponent: 0)
        
        let baseCurrency = self.currencies[baseCurrencyIndex]
        let toCurrency = self.currenciesExceptBase()[toCurrencyIndex]
        
        
        if Reachability.isConnectedToNetwork() != true {
            print("Internet connection: FAILD")
            self.label.text = "Отсутсвует интернет соединение"
            let alert = UIAlertController(title: "Отсутсвует интернет соединение", message: "Убедитесь, что ваше устройство подключено к сети интернет", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            }
            alert.addAction(cancelAction)
            self.present(alert, animated: true) {}
        } else {
            self.retrieveCurrencyRate(baseCurrency: baseCurrency, toCurrency: toCurrency) { [weak self] (value) in
                DispatchQueue.main.async(execute: {
                    if let strongSelf = self {
                        strongSelf.label.text = "1 \(baseCurrency) = \(value) \(toCurrency)"
                        strongSelf.dateLabel.text = "Курс на " + (self?.dateString)!
                        strongSelf.activityIndicator.stopAnimating()
                    }
                })
            }
        }
    

    }
    
    func requestCurrentcyRates(baseCurrentcy: String, parseHandler: @escaping (Data?, Error?) -> Void) {
        let url = URL(string: "https://api.fixer.io/latest?base=" + baseCurrentcy)
        
        let dataTask = URLSession.shared.dataTask(with: url!) {
            (dataRecieved, response, error) in
            
            parseHandler (dataRecieved, error)
        }
        
        dataTask.resume()
    }
    
    func parseCurrencyRatesResponse(data: Data?, toCurrency: String) -> String {
        var value: String = ""
        
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: []) as? Dictionary<String, Any>
            
            if let parsedJSON = json {
                print(parsedJSON)
                
                if let date = parsedJSON["date"] as? String {
                    self.dateFormatting(dateString: "\(date)")
                }
                
                if let rates = parsedJSON["rates"] as? Dictionary<String, Double> {
                    
                    if let rate = rates[toCurrency] {
                        value = "\(rate)"
                    } else {
                        value = "No rate for currency\"\(toCurrency)\" found"
                    }
                } else {
                    value = "No \"rates\" field found"
                }
            } else {
               value = "No JSON value parsed"
            }
        } catch {
            value = error.localizedDescription
        }
        
        return value
    }
    
    func retrieveCurrencyRate(baseCurrency: String, toCurrency: String, completion: @escaping (String) -> Void) {
        self.requestCurrentcyRates(baseCurrentcy: baseCurrency) {[weak self] (data, error) in
            var string = "No currency retrieved!"
            
            if let currentError = error {
                string = currentError.localizedDescription
            } else {
                if let strongSelf = self {
                    string = strongSelf.parseCurrencyRatesResponse(data: data, toCurrency: toCurrency)
                }
            }
            
            completion(string)
        }
    }
    
    
    
    func currenciesExceptBase() -> [String] {
        var currenciesExceptBase = currencies
        currenciesExceptBase.remove(at: pickerFrom.selectedRow(inComponent: 0))
        
        return currenciesExceptBase
    }
    
    func requestCurrentciesList() {
        let url = URL(string: "https://api.fixer.io/latest")
        let request = URLRequest(url: url!)
        
        let dataTask = URLSession.shared.dataTask(with: request) {
            (dataRecieved, response, error) in
            
            do {
                if let data = dataRecieved {
                
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, Any>
                
                    if let parsedJSON = json {
                        print(parsedJSON)
                    
                        if let rates = parsedJSON["rates"] as? Dictionary<String, Double>  {
                            let tempArr = Array(rates.keys)
                            
                            for key in tempArr {
                                
                                switch(key) {
                                case "RUB":
                                break
                                
                                case "EUR":
                                break
                                
                                case "USD":
                                break
                                
                                default:
                                self.currencies.append(key)
                                }
                            }
                            
                            self.pickerTo.reloadAllComponents()
                            self.pickerFrom.reloadAllComponents()
                        }
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
            
        }
        
        dataTask.resume()
    }
    
    func dateFormatting(dateString: String!) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let dateObj = dateFormatter.date(from: dateString)
        
        dateFormatter.dateFormat = "dd.MM.yyyy"
        self.dateString = String(dateFormatter.string(from: dateObj!))
    }
    
    @IBAction func refreshData(_ sender: UIButton) {
        self.requestCurrentCurrencyRate()
    }
}
