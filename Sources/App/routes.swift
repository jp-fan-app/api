//
//  Routes.swift
//  App
//
//  Created by Christoph Pageler on 12.08.18.
//


import Vapor


public func routes(_ router: Router) throws {

    router.group("api", "v1") { router in

        let token = User.tokenAuthMiddleware()
        let guardAuth = User.guardAuthMiddleware()
        let authenticated = router.grouped([token, guardAuth])

        // MARK: Auth

        let authController = AuthController()
        router.post("auth", "login", use: authController.login)
        authenticated.post("auth", "changePassword", use: authController.changePassword)

        // MARK: Manufacturers

        let manufacturerController = ManufacturerController()
        router.get("manufacturers", use: manufacturerController.index)
        router.get("manufacturers", Manufacturer.parameter, use: manufacturerController.show)
        authenticated.post("manufacturers", use: manufacturerController.create)
        authenticated.patch("manufacturers", Manufacturer.parameter, use: manufacturerController.patch)
        authenticated.delete("manufacturers", Manufacturer.parameter, use: manufacturerController.delete)

        router.get("manufacturers", Manufacturer.parameter, "models", use: manufacturerController.models)

        // MARK: Models

        let carModelController = CarModelController()
        router.get("models", use: carModelController.index)
        router.get("models", CarModel.parameter, use: carModelController.show)
        authenticated.post("models", use: carModelController.create)
        authenticated.patch("models", CarModel.parameter, use: carModelController.patch)
        authenticated.delete("models", CarModel.parameter, use: carModelController.delete)

        router.get("models", CarModel.parameter, "images", use: carModelController.images)
        router.get("models", CarModel.parameter, "stages", use: carModelController.stages)

        // MARK: Images

        let carImageController = CarImageController()
        router.get("images", use: carImageController.index)
        router.get("images", CarImage.parameter, use: carImageController.show)
        authenticated.post("images", use: carImageController.create)
        authenticated.patch("images", CarImage.parameter, use: carImageController.patch)
        authenticated.delete("images", CarImage.parameter, use: carImageController.delete)

        authenticated.post("images", CarImage.parameter, "upload", use: carImageController.upload)
        router.get("images", CarImage.parameter, "file", use: carImageController.file)

        // MARK: Stages

        let carStageController = CarStageController()
        router.get("stages", use: carStageController.index)
        router.get("stages", CarStage.parameter, use: carStageController.show)
        authenticated.post("stages", use: carStageController.create)
        authenticated.patch("stages", CarStage.parameter, use: carStageController.patch)
        authenticated.delete("stages", CarStage.parameter, use: carStageController.delete)

        router.get("stages", CarStage.parameter, "timings", use: carStageController.timings)
        router.get("stages", CarStage.parameter, "videos", use: carStageController.videos)
        authenticated.post("stages", CarStage.parameter, "videos", YoutubeVideo.parameter, use: carStageController.addVideoRelation)
        authenticated.delete("stages", CarStage.parameter, "videos", YoutubeVideo.parameter, use: carStageController.removeVideoRelation)
        router.get("stagesVideosRelations", use: carStageController.videosRelations)

        // MARK: Stage Timings

        let stageTimingController = StageTimingController()
        router.get("timings", use: stageTimingController.index)
        router.get("timings", StageTiming.parameter, use: stageTimingController.show)
        authenticated.post("timings", use: stageTimingController.create)
        authenticated.patch("timings", StageTiming.parameter, use: stageTimingController.patch)
        authenticated.delete("timings", StageTiming.parameter, use: stageTimingController.delete)

        // MARK: Videos

        let youtubeVideoController = YoutubeVideoController()
        router.get("videos", use: youtubeVideoController.index)
        router.get("videos", YoutubeVideo.parameter, use: youtubeVideoController.show)
        router.get("videos", "byVideoID", String.parameter, use: youtubeVideoController.byVideoID)
        router.get("videos", YoutubeVideo.parameter, "stages", use: youtubeVideoController.stages)
        router.get("videos", YoutubeVideo.parameter, "series", use: youtubeVideoController.series)

        // MARK: Devices

        let deviceController = DeviceController()
        authenticated.get("devices", use: deviceController.index)
        router.get("devices", String.parameter, use: deviceController.show)
        router.post("devices", use: deviceController.create)
        router.patch("devices", String.parameter, use: deviceController.patch)
        router.delete("devices", String.parameter, use: deviceController.delete)

        authenticated.post("devices", String.parameter, "setTestDevice", use: deviceController.setTestDevice)
        router.post("devices", String.parameter, "ping", use: deviceController.ping)
        router.get("devices", String.parameter, "notificationPreferences", use: deviceController.notificationPreferences)
        router.post("devices", String.parameter, "notificationPreferences", use: deviceController.createNotificationPreference)
        router.delete("devices", String.parameter, "notificationPreferences", Int.parameter, use: deviceController.deleteNotificationPreference)

        // MARK: Notifications

        let notificationController = NotificationController()
        authenticated.get("notifications", "devicesForEntityPair", use: notificationController.devicesForEntityPair)
        authenticated.post("notifications", "sendNotificationForEntityPair", use: notificationController.sendNotificationForEntityPair)
        router.post("notifications", "track", String.parameter, use: notificationController.track)

        // MARK: Access

        let accessController = AccessController()
        authenticated.get("access", use: accessController.index)
        authenticated.get("access", Access.parameter, use: accessController.show)
        authenticated.post("access", use: accessController.create)
        authenticated.patch("access", Access.parameter, use: accessController.patch)
        authenticated.delete("access", Access.parameter, use: accessController.delete)

        // MARK: Video Series

        let videoSerieController = VideoSerieController()
        router.get("videoSeries", use: videoSerieController.index)
        router.get("videoSeries", VideoSerie.parameter, use: videoSerieController.show)
        authenticated.post("videoSeries", use: videoSerieController.create)
        authenticated.patch("videoSeries", VideoSerie.parameter, use: videoSerieController.patch)
        authenticated.delete("videoSeries", VideoSerie.parameter, use: videoSerieController.delete)
        router.get("videoSeries", VideoSerie.parameter, "videos", use: videoSerieController.videos)
        authenticated.post("videoSeries", VideoSerie.parameter, "videos", YoutubeVideo.parameter, use: videoSerieController.addVideoRelation)
        authenticated.delete("videoSeries", VideoSerie.parameter, "videos", YoutubeVideo.parameter, use: videoSerieController.removeVideoRelation)

        router.get("videoSeriesVideosRelations", use: videoSerieController.videosRelations)
        authenticated.patch("videoSeries", VideoSerie.parameter, "videos", YoutubeVideo.parameter, use: videoSerieController.patchVideoRelation)

    }

}
