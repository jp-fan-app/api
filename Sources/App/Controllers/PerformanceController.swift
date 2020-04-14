//
//  PerformanceController.swift
//  App
//
//  Created by Christoph Pageler on 14.04.20.
//


import Vapor
import FluentMySQL


final class PerformanceController {

    struct LaSiSePerformance: Content {

        var items: [Item]

        struct Item: Content {

            var manufacturerName: String
            var modelID: Int
            var modelName: String
            var stageName: String
            var mainImageID: Int?
            var lasiseInSeconds: Double
            var lasiseFormatted: String

        }

    }

    func lasise(_ req: Request) -> Future<LaSiSePerformance> {
        let allCarManufacturersFuture = Manufacturer.query(on: req).filter(\.isDraft == false).all()
        let allCarModelsFuture = CarModel.query(on: req).filter(\.isDraft == false).all()
        let allCarStagesFuture = CarStage.query(on: req).filter(\.isDraft == false).all()

        return allCarModelsFuture
            .and(allCarStagesFuture)
            .and(allCarManufacturersFuture)
        .map { tuple in
            let ((allCarModels, allCarStages), allManufacturers) = tuple

            let sortedCarStagesWithValue = allCarStages
                .filter({ $0.lasiseInSeconds != nil })
            .sorted { (carStage1, carStage2) -> Bool in
                return carStage1.lasiseInSeconds ?? 999999 < carStage2.lasiseInSeconds ?? 999999
            }

            typealias MappingType = (CarModel, CarStage, Manufacturer)
            var mappedCarModelsWithStages = allCarModels.compactMap { carModel -> MappingType? in
                guard let bestCarStage = sortedCarStagesWithValue.first(where: { $0.carModelID == carModel.id }) else {
                    print("no stage for model")
                    return nil
                }
                guard let matchingManufacturer = allManufacturers.first(where: { $0.id == carModel.manufacturerID }) else {
                    print("manufacturer not found")
                    return nil
                }

                return (carModel, bestCarStage, matchingManufacturer)
            }

            mappedCarModelsWithStages = mappedCarModelsWithStages.sorted { (mappingType1, mappingType2) -> Bool in
                return mappingType1.1.lasiseInSeconds ?? 999999 < mappingType2.1.lasiseInSeconds ?? 999999
            }

            let items: [LaSiSePerformance.Item] = mappedCarModelsWithStages.map { tuple in
                let (carModel, carStage, manufacturer) = tuple

                let lasiseInSeconds = carStage.lasiseInSeconds ?? 999999
                return LaSiSePerformance.Item(manufacturerName: manufacturer.name,
                                              modelID: carModel.id ?? 99999,
                                              modelName: carModel.name,
                                              stageName: carStage.name,
                                              mainImageID: carModel.mainImageID,
                                              lasiseInSeconds: lasiseInSeconds,
                                              lasiseFormatted: lasiseInSeconds.formattedLaSiSeDisplayString())
            }

            return LaSiSePerformance(items: items)
        }
    }

}


private extension Double {

    func formattedLaSiSeDisplayString() -> String {
        let seconds = self

        let minutesInt = Int(floor(seconds / 60.0))
        let secondsInt = Int(seconds - Double(minutesInt * 60))
        let fractionInt = Int((Double(seconds) - floor(seconds)) * 10)

        let minutesString = minutesInt < 10 ? "0\(minutesInt)" : "\(minutesInt)"
        let secondsString = secondsInt < 10 ? "0\(secondsInt)" : "\(secondsInt)"

        return "\(minutesString):\(secondsString),\(fractionInt)"
    }

}
