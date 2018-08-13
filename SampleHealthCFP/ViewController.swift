//
//  ViewController.swift
//  SampleHealthCFP
//
//  Created by ngovantucuong on 8/10/18.
//  Copyright © 2018 ngovantucuong. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {

    // MARK: - IBOulet
    @IBOutlet weak var distanceWalkingLabel: UILabel!
    @IBOutlet weak var totalStepsLabel: UILabel!
    
    //MARK: Property
    let healthStore = HKHealthStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func authoriseHealthKitAccess(_ sender: UIButton) {
        let healthKitType: Set = [
            // Acess step count
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        healthStore.requestAuthorization(toShare: healthKitType, read: healthKitType) { (bool, error) in
            if error != nil {
                print("Error authorization access")
            } else {
                print("Acess successfull")
            }
        }
    }
    
    fileprivate func getTodaysSteps(complete: @escaping(_ value: Double) -> Void) {
        guard let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let now = Date()
        let startDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
            var resultCount: Double = 0.0
            guard let result = result else {
                print("Failed to fetch steps rate")
                complete(Double(resultCount))
                return
            }
            
            if let sum = result.sumQuantity() {
                resultCount = sum.doubleValue(for: HKUnit.count())
            }
            DispatchQueue.main.async {
                complete(resultCount)
            }
        }
        healthStore.execute(query)
    }
    
    fileprivate func getTodaysWalkDistance(complete: @escaping(_ value: Double) -> Void) {
        guard let walkDistanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
                return
        }
        let now = Date()
        let startDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: walkDistanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
            var resultCount: Double = 0.0
            guard let result = result else {
                print("Failed to fetch steps rate")
                complete(Double(resultCount))
                return
            }
            
            if let sum = result.sumQuantity() {
                resultCount = sum.doubleValue(for: HKUnit.meter())
            }
            DispatchQueue.main.async {
                complete(resultCount)
            }
        }
        healthStore.execute(query)
    }
    
    @IBAction func getStepsAction(_ sender: Any) {
        getTodaysSteps { [weak self] (steps) in
            DispatchQueue.main.async {
                self?.totalStepsLabel.text = String(describing: steps)
                self?.getTodaysWalkDistance(complete: { (walk) in
                    self?.distanceWalkingLabel.text = "\(walk)"
                })
            }
        }
    }
}

