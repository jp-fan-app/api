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
        let adminMiddleware = AdminMiddleware()
        let authenticated = router.grouped([token, guardAuth])
        let admin = router.grouped([token, guardAuth, adminMiddleware])

        // MARK: Auth

        let authController = AuthController()
        router.post("auth", "login", use: authController.login)
        authenticated.post("auth", "changePassword", use: authController.changePassword)

        // MARK: Manufacturers

        let manufacturerController = ManufacturerController()
        router.get("manufacturers", use: manufacturerController.index)
        router.get("manufacturers", Manufacturer.parameter, use: manufacturerController.show)
        router.get("manufacturers", Manufacturer.parameter, "models", use: manufacturerController.models)
        authenticated.post("manufacturers", use: manufacturerController.create)
        authenticated.get("manufacturers", "draft", use: manufacturerController.indexDraft)
        admin.patch("manufacturers", Manufacturer.parameter, use: manufacturerController.patch)
        admin.post("manufacturers", Manufacturer.parameter, "publish", use: manufacturerController.publish)
        admin.delete("manufacturers", Manufacturer.parameter, use: manufacturerController.delete)

        // MARK: Models

        let carModelController = CarModelController()
        router.get("models", use: carModelController.index)
        router.get("models", CarModel.parameter, use: carModelController.show)
        router.get("models", CarModel.parameter, "images", use: carModelController.images)
        router.get("models", CarModel.parameter, "stages", use: carModelController.stages)
        authenticated.post("models", use: carModelController.create)
        authenticated.get("models", "draft", use: carModelController.indexDraft)
        admin.patch("models", CarModel.parameter, use: carModelController.patch)
        admin.post("models", CarModel.parameter, "publish", use: carModelController.publish)
        admin.delete("models", CarModel.parameter, use: carModelController.delete)

        // MARK: Images

        let carImageController = CarImageController()
        router.get("images", use: carImageController.index)
        router.get("images", CarImage.parameter, use: carImageController.show)
        router.get("images", CarImage.parameter, "file", use: carImageController.file)
        authenticated.post("images", use: carImageController.create)
        authenticated.post("images", CarImage.parameter, "upload", use: carImageController.upload)
        authenticated.get("images", "draft", use: carImageController.indexDraft)
        admin.patch("images", CarImage.parameter, use: carImageController.patch)
        admin.post("images", CarImage.parameter, "publish", use: carImageController.publish)
        admin.delete("images", CarImage.parameter, use: carImageController.delete)

        // MARK: Stages

        let carStageController = CarStageController()
        router.get("stages", use: carStageController.index)
        router.get("stages", CarStage.parameter, use: carStageController.show)
        router.get("stages", CarStage.parameter, "timings", use: carStageController.timings)
        router.get("stages", CarStage.parameter, "videos", use: carStageController.videos)
        authenticated.get("stages", CarStage.parameter, "videos", "draft", use: carStageController.videosDraft)
        router.get("stagesVideosRelations", use: carStageController.videosRelations)
        authenticated.post("stages", use: carStageController.create)
        authenticated.post("stages", CarStage.parameter, "videos", YoutubeVideo.parameter, use: carStageController.addVideoRelation)
        authenticated.get("stages", "draft", use: carStageController.indexDraft)
        admin.patch("stages", CarStage.parameter, use: carStageController.patch)
        admin.post("stages", CarStage.parameter, "publish", use: carStageController.publish)
        admin.post("stages", CarStage.parameter, "videos", YoutubeVideo.parameter, "publish", use: carStageController.publishVideoRelation)
        admin.delete("stages", CarStage.parameter, use: carStageController.delete)
        admin.delete("stages", CarStage.parameter, "videos", YoutubeVideo.parameter, use: carStageController.removeVideoRelation)

        // MARK: Stage Timings

        let stageTimingController = StageTimingController()
        router.get("timings", use: stageTimingController.index)
        router.get("timings", StageTiming.parameter, use: stageTimingController.show)
        authenticated.post("timings", use: stageTimingController.create)
        authenticated.get("timings", "draft", use: stageTimingController.indexDraft)
        admin.patch("timings", StageTiming.parameter, use: stageTimingController.patch)
        admin.post("timings", StageTiming.parameter, "publish", use: stageTimingController.publish)
        admin.delete("timings", StageTiming.parameter, use: stageTimingController.delete)

        // MARK: Videos

        let youtubeVideoController = YoutubeVideoController()
        router.get("videos", use: youtubeVideoController.index)
        router.get("videos", YoutubeVideo.parameter, use: youtubeVideoController.show)
        router.get("videos", "byVideoID", String.parameter, use: youtubeVideoController.byVideoID)
        router.get("videos", YoutubeVideo.parameter, "stages", use: youtubeVideoController.stages)
        router.get("videos", YoutubeVideo.parameter, "series", use: youtubeVideoController.series)

        // MARK: Devices

        let deviceController = DeviceController()
        router.get("devices", String.parameter, use: deviceController.show)
        router.post("devices", use: deviceController.create)
        router.patch("devices", String.parameter, use: deviceController.patch)
        router.delete("devices", String.parameter, use: deviceController.delete)
        router.post("devices", String.parameter, "ping", use: deviceController.ping)
        router.get("devices", String.parameter, "notificationPreferences", use: deviceController.notificationPreferences)
        router.post("devices", String.parameter, "notificationPreferences", use: deviceController.createNotificationPreference)
        router.delete("devices", String.parameter, "notificationPreferences", Int.parameter, use: deviceController.deleteNotificationPreference)
        admin.get("devices", use: deviceController.index)
        admin.post("devices", String.parameter, "setTestDevice", use: deviceController.setTestDevice)

        // MARK: Notifications

        let notificationController = NotificationController()
        router.post("notifications", "track", String.parameter, use: notificationController.track)
        admin.get("notifications", "devicesForEntityPair", use: notificationController.devicesForEntityPair)
        admin.post("notifications", "sendNotificationForEntityPair", use: notificationController.sendNotificationForEntityPair)

        // MARK: Access

        let accessController = AccessController()
        admin.get("access", use: accessController.index)
        admin.get("access", Access.parameter, use: accessController.show)
        admin.post("access", use: accessController.create)
        admin.patch("access", Access.parameter, use: accessController.patch)
        admin.delete("access", Access.parameter, use: accessController.delete)

        // MARK: - User
        let userController = UserController()
        admin.get("user", use: userController.index)
        admin.get("user", User.parameter, use: userController.show)
        admin.post("user", use: userController.create)
        admin.patch("user", User.parameter, use: userController.patch)
        admin.post("user", User.parameter, "changePassword", use: userController.changePassword)
        admin.get("user", User.parameter, "tokens", use: userController.showTokens)
        admin.delete("user", User.parameter, "tokens", use: userController.deleteToken)
        admin.delete("user", User.parameter, use: userController.delete)

        // MARK: Video Series

        let videoSerieController = VideoSerieController()
        router.get("videoSeries", use: videoSerieController.index)
        router.get("videoSeries", VideoSerie.parameter, use: videoSerieController.show)
        router.get("videoSeries", VideoSerie.parameter, "videos", use: videoSerieController.videos)
        router.get("videoSeriesVideosRelations", use: videoSerieController.videosRelations)
        authenticated.get("videoSeries", "draft", use: videoSerieController.indexDraft)
        authenticated.get("videoSeries", VideoSerie.parameter, "videos", "draft", use: videoSerieController.videosDraft)
        authenticated.post("videoSeries", VideoSerie.parameter, "videos", YoutubeVideo.parameter, use: videoSerieController.addVideoRelation)
        authenticated.post("videoSeries", use: videoSerieController.create)
        admin.patch("videoSeries", VideoSerie.parameter, use: videoSerieController.patch)
        admin.post("videoSeries", VideoSerie.parameter, "publish", use: videoSerieController.publish)
        admin.delete("videoSeries", VideoSerie.parameter, use: videoSerieController.delete)
        admin.delete("videoSeries", VideoSerie.parameter, "videos", YoutubeVideo.parameter, use: videoSerieController.removeVideoRelation)
        admin.patch("videoSeries", VideoSerie.parameter, "videos", YoutubeVideo.parameter, use: videoSerieController.patchVideoRelation)
        admin.post("videoSeries", VideoSerie.parameter, "videos", YoutubeVideo.parameter, "publish", use: videoSerieController.publishVideoRelation)

    }

}
