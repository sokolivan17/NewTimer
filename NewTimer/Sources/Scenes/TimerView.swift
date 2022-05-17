//
//  TimerView.swift
//  NewTimer
//
//  Created by Ваня Сокол on 16.05.2022.
//

import UIKit

class TimerView: UIViewController {

    private lazy var trackLayer = CAShapeLayer()
    private lazy var shapeLayer = CAShapeLayer()

    private var timer = Timer()
    private var durationTimer = Metric.workTimeValue {
        didSet {
            labelTimer.text = durationTimer < Metric.workTimeValue ? "00:0\(durationTimer)" : "00:\(durationTimer)"
        }
    }

    private var isStarted = false {
        didSet {
            button.isSelected = isStarted
        }
    }
    private var isWorkTime = true {
        didSet {
            durationTimer = isWorkTime ? Metric.workTimeValue : Metric.relaxTimeValue
            labelTimer.textColor = isWorkTime ? Color.workState : Color.relaxState
            setButtonColor()

        }
    }

    var state: State = .start

    private lazy var labelTimer: UILabel = {
        var labelTimer = UILabel()
        labelTimer.text = String(format: "%02i:%02i", Metric.minutes, Metric.seconds)
        labelTimer.textColor = isWorkTime ? Color.workState : Color.relaxState
        labelTimer.font = .systemFont(ofSize: Metric.labelSize)
        labelTimer.sizeToFit()

        return labelTimer
    }()

    private lazy var button: UIButton = {
        let currentColor = isWorkTime ? Color.workState : Color.relaxState
        var button = UIButton(type: .system)
        let configurationImage = UIImage.SymbolConfiguration(pointSize: Metric.buttonSize)
        button.tintColor = .clear
        button.setPreferredSymbolConfiguration(configurationImage, forImageIn: .normal)
        button.setImage(Icons.start?.withTintColor(currentColor, renderingMode: .alwaysOriginal), for: .normal)
        button.setImage(Icons.pause?.withTintColor(currentColor, renderingMode: .alwaysOriginal), for: .selected)

        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)

        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray

        setupHierarchy()
        setupLayout()

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        createCircleWithAnimation()
        setCircleColor()
    }

    // MARK: - Settings

    private func setupHierarchy() {
        view.addSubview(labelTimer)
        view.addSubview(button)

        view.layer.addSublayer(trackLayer)
        view.layer.addSublayer(shapeLayer)
    }

    private func setupLayout() {
        labelTimer.translatesAutoresizingMaskIntoConstraints = false
        labelTimer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        labelTimer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30).isActive = true

        button.translatesAutoresizingMaskIntoConstraints = false
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 80).isActive = true

    }

    private func setButtonColor() {
        let currentColor = isWorkTime ? Color.workState : Color.relaxState
        button.setImage(Icons.start?.withTintColor(currentColor, renderingMode: .alwaysOriginal), for: .normal)
        button.setImage(Icons.pause?.withTintColor(currentColor, renderingMode: .alwaysOriginal), for: .selected)

    }

    private func createCircleWithAnimation() {
        let center = view.center
        let radius = min(view.frame.width, view.frame.height) / 2.2
        let startAngle = 3 / 2 * CGFloat.pi
        let endAngle = startAngle - (2 * CGFloat.pi)


        let circlePath = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)

        trackLayer.path = circlePath.cgPath
        trackLayer.strokeColor = Color.workState.cgColor
        trackLayer.lineWidth = Metric.widthCircle
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = CAShapeLayerLineCap.round

        shapeLayer.path = circlePath.cgPath
        shapeLayer.strokeColor = Color.workState.cgColor
        shapeLayer.lineWidth = Metric.widthCircle
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        shapeLayer.strokeEnd = 1
    }

    private func setCircleColor() {
        let currentColorTrack = isWorkTime ? Color.workTrackLayer : Color.relaxTrackLayer
        let currentColorShape = isWorkTime ? Color.workShapeLayer : Color.relaxShapeLayer
        trackLayer.strokeColor = currentColorTrack.cgColor
        shapeLayer.strokeColor = currentColorShape.cgColor
    }

    private func pauseAnimationCircle() {
        let pauseTime = shapeLayer.convertTime(CACurrentMediaTime(), from: nil)
        shapeLayer.speed = 0
        shapeLayer.timeOffset = pauseTime
    }

    private func startAnimationCircle() {
        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        basicAnimation.speed = 1.0
        basicAnimation.toValue = 0
        basicAnimation.duration = CFTimeInterval(durationTimer)
        basicAnimation.fillMode = CAMediaTimingFillMode.forwards
        basicAnimation.isRemovedOnCompletion = true
        shapeLayer.add(basicAnimation, forKey: "basicAnimation")

    }

    private func resumeAnimationCircle() {
        let pausedTime = shapeLayer.timeOffset
        shapeLayer.speed = 1.0
        shapeLayer.timeOffset = 0.0
        shapeLayer.beginTime = 0.0
        let timeStart = shapeLayer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        shapeLayer.beginTime = timeStart
    }


    // MARK: - Actions

    @objc private func timerAction() {
        guard durationTimer > 0 else {
            state = .start
            isStarted = !isStarted
            isWorkTime = !isWorkTime
            timer.invalidate()
            return
        }

        durationTimer -= 1
    }

    @objc private func buttonAction() {
        switch state {
        case .start:
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
            startAnimationCircle()
        case .pause:
            timer.invalidate()
            pauseAnimationCircle()
        case .resume:
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
            resumeAnimationCircle()
        }

        isStarted = !isStarted
        if isStarted {
            state = .pause
        } else {
            state = .resume
        }

}

}

extension TimerView {
    enum Icons {
        static let start = UIImage(systemName: "play")
        static let pause = UIImage(systemName: "pause")

    }

    enum Metric {
        static let labelSize: CGFloat = 80
        static let buttonSize: CGFloat = 60
        static let workTimeValue = 10
        static let relaxTimeValue = 5
        static let minutes = workTimeValue / 60 % 60
        static let seconds = workTimeValue % 60
        static let widthCircle: CGFloat = 10
    }

    enum Color {
        static let workState = UIColor.black
        static let relaxState = UIColor.white
        static let relaxTrackLayer = UIColor.white.withAlphaComponent(0.2)
        static let relaxShapeLayer = UIColor.white.withAlphaComponent(0.8)
        static let workTrackLayer = UIColor.black.withAlphaComponent(0.2)
        static let workShapeLayer = UIColor.black.withAlphaComponent(0.8)
    }

    enum State {
        case start, pause, resume
    }

}

