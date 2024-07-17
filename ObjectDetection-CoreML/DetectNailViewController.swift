//
//  DetectNailViewController.swift
//  ObjectDetection-CoreML
//
//  Created by Huy Dang on 22/6/24.
//  Copyright © 2024 tucan9389. All rights reserved.
//


import UIKit
import Vision
import CoreMedia
import SnapKit
import ARKit
import Photos


class DetectNailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    enum MeasureState {
        case lengthCalc
        case breadthCalc
    }
    
    // MARK: - UI Properties
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var boxesView: DrawingBoundingBoxView!
    @IBOutlet weak var inferenceLabel: UILabel!
    @IBOutlet weak var etimeLabel: UILabel!
    @IBOutlet weak var fpsLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var testImageView: UIImageView!
    @IBOutlet weak var sceneView: MeasureSCNView!
    
    var labelsTableView: UITableView!
    var currentState: MeasureState = MeasureState.lengthCalc
    var lengthNodes = NSMutableArray()
    var breadthNodes = NSMutableArray()
    var lineNodes = NSMutableArray()
    var captureButton: UIButton!
    
    var nodeColor: UIColor {
        get {
            return nodeColor(forState: currentState, alphaComponent: 0.7)
        }
    }
    
    private lazy var sliderConf: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.01
        slider.maximumValue = 1
        slider.value = 0.25
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        return slider
    }()
    
    private lazy var labelSliderConf: UILabel = {
        let label = UILabel()
        label.text = "0.25 Confidence Threshold"
        label.textColor = .white
        return label
    }()
    
    
    let nodeRadius = CGFloat(0.015)

    // MARK: - Core ML model
    lazy var objectDectectionModel = { return try? best() }()
    
    // MARK: - Vision Properties
    var request: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
    var isInferencing = false
    
    // MARK: - AV Property
    var videoCapture: VideoCapture?
    let semaphore = DispatchSemaphore(value: 1)
    var lastExecution = Date()
    
    // MARK: - TableView Data
    var predictions: [VNRecognizedObjectObservation] = []
    
    // MARK: - Performance Measurement Property
    private let 👨‍🔧 = 📏()
    let maf1 = MovingAverageFilter()
    let maf2 = MovingAverageFilter()
    let maf3 = MovingAverageFilter()
    
    // MARK: - View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let videoPreview = videoPreview else {
            print("videoPreview is nil")
            return
        }
        
        setupLabelsTableView()
        setUpModel()
        setUpCamera()
        
        👨‍🔧.delegate = self
        setupCoordinateSystemView()
        
        setupResetButton()
        
        view.addSubview(labelSliderConf)
        
        labelSliderConf.snp.makeConstraints { make in
            make.top.equalTo(videoPreview.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(12)
        }
        
        view.addSubview(sliderConf)
        
        sliderConf.snp.makeConstraints { make in
            make.top.equalTo(labelSliderConf.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(12)
            make.height.equalTo(30)
            make.width.equalTo(171)
        }
        
    }
    
    func setupLabelsTableView() {
        labelsTableView = UITableView()
        labelsTableView.delegate = self
        labelsTableView.dataSource = self
        labelsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "InfoCell")
        self.view.addSubview(labelsTableView)
        labelsTableView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.top.equalTo(videoPreview.snp.bottom)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    func setupResetButton() {
        captureButton = UIButton(type: .system)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.setTitle("Capture", for: .normal)
        captureButton.addTarget(self, action: #selector(captureAnchors), for: .touchUpInside)
        view.addSubview(captureButton)
        
        captureButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-50)
            make.centerX.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(40)
        }
    }
    
    
    @objc func captureAnchors() {
        let settings = AVCapturePhotoSettings()
        self.videoCapture?.cameraOutput.capturePhoto(with: settings, delegate: self as AVCapturePhotoCaptureDelegate)
//        let vc = ShowNailController(nails: predictions)
//        
//        present(vc, animated: true)   
    }
    
    @objc func sliderChanged(_ sender: Any) {
        let conf = Double(round(100 * sliderConf.value)) / 100
        self.labelSliderConf.text = String(conf) + " Confidence Threshold"
        visionModel?.featureProvider = ThresholdProvider(iouThreshold: 0.45, confidenceThreshold: conf)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.videoCapture?.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoCapture?.stop()
    }
    
    func setUpModel() {
        guard let objectDectectionModel = objectDectectionModel else { fatalError("fail to load the model") }
        if let visionModel = try? VNCoreMLModel(for: objectDectectionModel.model) {
            self.visionModel = visionModel
            self.visionModel?.featureProvider = ThresholdProvider()
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request?.imageCropAndScaleOption = .scaleFill
        } else {
            fatalError("fail to create vision model")
        }
    }
    
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture?.delegate = self
        videoCapture?.fps = 30
        videoCapture?.setUp(sessionPreset: .vga640x480) { success in
            if success {
                if let previewLayer = self.videoCapture?.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                self.videoCapture?.start()
            }
        }
    }
    
    func setupCoordinateSystemView() {
        let coordinateSystemView = CoordinateSystemView()
        coordinateSystemView.backgroundColor = .clear
        self.view.addSubview(coordinateSystemView)
        coordinateSystemView.snp.makeConstraints { make in
            make.center.equalTo(videoPreview.snp.center)
            make.width.equalTo(videoPreview.snp.width)
            make.height.equalTo(videoPreview.snp.height)
        }
    }
    
    func addPoint() {
        let screenCenterPoint = CGPoint(x: 214.0, y: 463.0)
        let pointLocation = view.convert(screenCenterPoint, to: sceneView)
        
        guard let hitResultPosition = sceneView.hitResult(forPoint: pointLocation) else {
            return
        }
        
        print("screenCenterPoint =  \(screenCenterPoint)")
        print("hitResultPosition =  \(hitResultPosition)")
        
        // To prevent multiple taps
        let nodes = nodesList(forState: currentState)
        
        // Create a sphere and set its color using a material
        let sphere = SCNSphere(radius: nodeRadius)
        let material = SCNMaterial()
        material.diffuse.contents = nodeColor
        sphere.materials = [material]
        
        let node = SCNNode(geometry: sphere)
        node.position = hitResultPosition
        sceneView.scene.rootNode.addChildNode(node)
        
        // Add the sphere to the list.
        nodes.add(node)
    }

    
    private func nodesList(forState state: MeasureState) -> NSMutableArray {
        switch state {
        case .lengthCalc:
            return lengthNodes
        case .breadthCalc:
            return breadthNodes
        }
    }
    
    private func nodeColor(forState state: MeasureState, alphaComponent: CGFloat) -> UIColor {
        switch state {
        case .lengthCalc:
            return UIColor.red.withAlphaComponent(alphaComponent)
        case .breadthCalc:
            return UIColor.green.withAlphaComponent(alphaComponent)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizePreviewLayer()
    }
    
    func resizePreviewLayer() {
        videoCapture?.previewLayer?.frame = videoPreview.bounds
    }
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        print("Button was tapped")
        startObjectDetection()
    }
    
    func startObjectDetection() {
        print("Object detection started")
    }
}

extension DetectNailViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        if !self.isInferencing, let pixelBuffer = pixelBuffer {
            self.isInferencing = true
            self.👨‍🔧.🎬👏()
            self.predictUsingVision(pixelBuffer: pixelBuffer)
        }
    }
}

extension DetectNailViewController {
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        guard let request = request else { fatalError() }
        self.semaphore.wait()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }
    
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        self.👨‍🔧.🏷(with: "endInference")
        if let predictions = request.results as? [VNRecognizedObjectObservation] {
            self.predictions = predictions
//            self.nails = []
//            self.nails = predictions
            DispatchQueue.main.async {
                self.boxesView.predictedObjects = predictions
                self.labelsTableView.reloadData()
                self.👨‍🔧.🎬🤚()
                self.isInferencing = false
            }
        } else {
            self.👨‍🔧.🎬🤚()
            self.isInferencing = false
        }
        self.semaphore.signal()
    }
}

extension DetectNailViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return predictions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell") else {
            return UITableViewCell()
        }
        
        addPoint()
        let rectString = predictions[indexPath.row].boundingBox.toString(digit: 2, width: videoPreview.frame.width, height: videoPreview.frame.height)
        let confidence = predictions[indexPath.row].labels.first?.confidence ?? -1
        let confidenceString = String(format: "%.3f", confidence)
        
        cell.textLabel?.text = "Point \(indexPath.row + 1): \(rectString)"
        return cell
    }
}

extension DetectNailViewController: 📏Delegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int) {
        DispatchQueue.main.async {
            self.maf1.append(element: Int(inferenceTime * 1000.0))
            self.maf2.append(element: Int(executionTime * 1000.0))
            self.maf3.append(element: fps)
            
            self.inferenceLabel.text = "inference: \(self.maf1.averageValue) ms"
            self.etimeLabel.text = "execution: \(self.maf2.averageValue) ms"
            self.fpsLabel.text = "fps: \(self.maf3.averageValue)"
        }
    }
}

class MovingAverageFilter {
    private var arr: [Int] = []
    private let maxCount = 10
    
    public func append(element: Int) {
        arr.append(element)
        if arr.count > maxCount {
            arr.removeFirst()
        }
    }
    
    public var averageValue: Int {
        guard !arr.isEmpty else { return 0 }
        let sum = arr.reduce(0) { $0 + $1 }
        return Int(Double(sum) / Double(arr.count))
    }
}

extension DetectNailViewController {
    func calculateDistanceBetweenPoints(point1: CGPoint, point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx*dx + dy*dy)
    }
}

class SecondViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Second View"
    }
}

extension DetectNailViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("error occurred : \(error.localizedDescription)")
        }
        if let dataImage = photo.fileDataRepresentation() {
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let image = UIImage(cgImage: cgImageRef, scale: 0.5, orientation: UIImage.Orientation.right)
            
            print("Image: \(image)")
            
            testImageView.image = image
        } else {
            print("AVCapturePhotoCaptureDelegate Error")
        }
    }
}
