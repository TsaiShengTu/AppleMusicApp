//
//  ViewController.swift
//  musicApp
//
//  Created by Sheng-Yu on 2022/11/18.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    var pauseTime:CMTime?
    
    //播放器
    let player = AVQueuePlayer()
    //播放項目
    var playerItem:AVPlayerItem?
    //重複播放使用器
    var playerLooper: AVPlayerLooper?
    //播放的單首曲目
    var songPlayed: Music?
    
    var isplay:Bool = false {
        didSet{
            playPauseButton.isSelected = isplay
        }
    }
    
    


    let musics = [Music(songName: "家常音樂", singer: "Soft Lip", image: "image0", musicName: "家常音樂"),Music(songName: "台灣的心跳聲", singer: "蔡依林", image: "image1", musicName: "台灣的心跳聲"),Music(songName: "低電量", singer: "呂士軒", image: "image2", musicName: "低電量")]
    
    var musicIndex = 0
    
    
    
    @IBOutlet weak var imageViews: UIImageView!
    
    
    
    @IBOutlet weak var playingSlider: UISlider!
    
    @IBOutlet weak var currentTimeLabel: UILabel!
    
    @IBOutlet weak var remainTimeLabel: UILabel!
    
    
    @IBOutlet weak var reverseBackgroundView: UIView!
    @IBOutlet weak var forwardBackgroundView: UIView!
    @IBOutlet weak var playPauseBackgroundView: UIView!
    
    
    
    @IBOutlet weak var reverseButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    
    
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var singerNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        songPlayed = musics[musicIndex]
        configurePlayer(song:songPlayed!)
        currentTime()
        
        //推播通知觀察器
        //會觀察音樂跑到哪裡，AVPlayerItemDidPlayToEndTime是觀察音樂播完的時候，跑下面的函式．
        //
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { (_) in
            self.repeatStateCheck()
        }
        
//        [reverseBackgroundView, playPauseBackgroundView, forwardBackgroundView].forEach { view in
//            view?.layer.cornerRadius = view!.frame.height / 2
//            view?.clipsToBounds = true
//            view?.alpha = 0.0
//        }
        
        //先把後面的View的alpha調成0
        reverseBackgroundView.layer.cornerRadius = reverseBackgroundView.frame.height/2
        reverseBackgroundView.clipsToBounds = true
        reverseBackgroundView.alpha = 0.0

        playPauseBackgroundView.layer.cornerRadius = reverseBackgroundView.frame.height/2
        playPauseBackgroundView.clipsToBounds = true
        playPauseBackgroundView.alpha = 0.0

        forwardBackgroundView.layer.cornerRadius = reverseBackgroundView.frame.height/2
        forwardBackgroundView.clipsToBounds = true
        forwardBackgroundView.alpha = 0.0
        
        
        
    }
    func repeatStateCheck(){
        //自動播放下一首且是重複清單播放
        musicIndex = musics.firstIndex(of:songPlayed!)!
        print("musicIndex",musicIndex)
        self.musicIndex += 1
        if musicIndex == musics.count {
            self.musicIndex = 0
        }
        print("musicIndex",musicIndex)
        songPlayed = musics[musicIndex]
        configurePlayer(song: songPlayed!)
        if let url = Bundle.main.url(forResource: songPlayed?.musicName, withExtension: "mp3"){
            playerItem = AVPlayerItem(url:url)
            playerLooper = AVPlayerLooper(player: player, templateItem: playerItem!)
            player.play()
        }
        
    }
    
        //呼叫單曲
    func configurePlayer(song: Music){
        //生成路徑
        let url = Bundle.main.url(forResource: song.musicName, withExtension: "mp3")
        playerItem = AVPlayerItem(url: url!)
        //播放當前曲目
        player.replaceCurrentItem(with: playerItem)
        
        //取得音樂項目的時間
        let duration = playerItem?.asset.duration
        //用CMTimeGetSeconds開啟
        let seconds = CMTimeGetSeconds(duration!)
        
        //設定滑桿
        playingSlider.minimumValue = 0
        playingSlider.maximumValue = Float(seconds)
        songNameLabel.text = song.songName
        singerNameLabel.text = song.singer
        imageViews.image = UIImage(named: song.image)
        print("跑了configurePlayer")
    }
    
    //計算音樂播放的時間
    func currentTime() {
        player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 1), queue: DispatchQueue.main, using: { (CMTime) in
            
            //status 如果失敗的話就會移除AVplayer
            if self.player.currentItem?.status == .readyToPlay {
                //已跑秒數
                let currentTime = CMTimeGetSeconds(self.player.currentTime())
                //進度條跟著currentTime更新
                self.playingSlider.value = Float(currentTime)
                /*
                 currentTimeLabel跟著currentTime變換顯示
                 remainTimeLabel由slider最大值減去經過時間前方再加個負號
                 ex: 經過時間：30秒，整首4分30秒
                 max = 270, 270 - 30 = 240, formatConversion(240) = 4分鐘
                 remainTimeLabel = -formatConversion(240) = -4分鐘
                 */
                
                self.currentTimeLabel.text = self.formatConversion(time: currentTime)
                self.remainTimeLabel.text = "-\(self.formatConversion(time: Double(self.playingSlider.maximumValue) - currentTime))"
            }
        })
    }
    
    // 時間秒數轉換　成字串
    func formatConversion(time: Double) -> String {
        // quotient為商數，remainder為餘數，returnStr回傳“幾分：幾秒”
        
        //quotientAndRemainder 除法
        let answer = Int(time).quotientAndRemainder(dividingBy: 60)
        let returnStr = "\(answer.quotient):\(String(format: "%.2d", answer.remainder))"
        return returnStr
    }

    
    @IBAction func touchedUpInside(_ sender: UIButton) {
        let buttonBackground:UIView
        
        switch sender{
        case reverseButton:
            pauseTime = nil
            buttonBackground = reverseBackgroundView
            if player.currentTime().seconds > 5 && isplay == true{
                let Time = CMTime(value: 0, timescale: 1)
                player.seek(to: Time)
                player.play()
            }
            else if isplay == true &&  player.currentTime().seconds <= 5 {
                musicIndex -= 1
                if musicIndex < 0 {
                    musicIndex = musics.count - 1
                }
                //目前單首的位置
                songPlayed = musics[musicIndex]
                //初始化的畫面設計
                configurePlayer(song: songPlayed!)
                
                player.play()
                print("播歌reverseButton",songPlayed!.musicName)
                
            }
            else if isplay == false{
                
//                let playertime = player.seek(to: CMTime(value: 0, timescale: 1))
//                player.play()
//                print("playertime",playertime)
//                let currentTime = CMTimeGetSeconds(self.player.currentTime())
//                print("currentTime",currentTime)
//
//                //進度條跟著currentTime更新
//                self.playingSlider.value = Float(currentTime)
//                self.currentTimeLabel.text = self.formatConversion(time: currentTime)
//                self.remainTimeLabel.text = "-\(self.formatConversion(time: Double(self.playingSlider.maximumValue) - currentTime))"
//
                player.play()
                player.pause()
                print("暫停播歌reverseButton",songPlayed!.musicName)
                musicIndex -= 1
                if musicIndex < 0 {
                    musicIndex = musics.count - 1
                }
                //目前單首的位置
                songPlayed = musics[musicIndex]
                //初始化的畫面設計
                configurePlayer(song: songPlayed!)

            }
            
            
            print("goback\(songPlayed!.musicName)",musicIndex)

        case playPauseButton:
            buttonBackground = playPauseBackgroundView
            
//            if isplay == true {
//                isplay = false
//                print("跑進來了1",isplay)
//
//            } else {
//                isplay = true
//                print("跑進來了2",isplay)
//            }
            if !isplay {
                playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                currentTime()
                isplay = true
                player.play()
                UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 3, options: [], animations: {
                    //恢復原狀
                    self.imageViews.transform = CGAffineTransform.identity
                }, completion: nil)
                print("播歌playPauseButton",songPlayed!.musicName)

            }else {
                player.pause()
                playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                isplay = false
                UIView.animate(withDuration: 0.5) {
                    self.imageViews.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                }
                print("暫停播歌playPauseButton",songPlayed!.musicName)
            }
            

//            if isplay == true {
//                //目前單首的位置
//                songPlayed = musics[musicIndex]
//                //初始化的畫面設計
//                configurePlayer(song: songPlayed!)
//
//
////                player.seek(to:pauseTime ?? CMTime(value: 0, timescale: 1))
//                currentTime()
//                player.play()
//                UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 3, options: [], animations: {
//                    //恢復原狀
//                    self.imageViews.transform = CGAffineTransform.identity
//                }, completion: nil)
//                print("播歌playPauseButton",songPlayed!.musicName)
//
//            }
//            else{
////                pauseTime = player.currentTime()
//                player.pause()
//                UIView.animate(withDuration: 0.5) {
//                    self.imageViews.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
//                }
//                print("暫停播歌playPauseButton",songPlayed!.musicName)
//            }
        case forwardButton:
            buttonBackground = forwardBackgroundView
            musicIndex = ( musicIndex + 1 ) % musics.count
            let index = musics.firstIndex(of: songPlayed!) ?? 0
            print (index)
            
//            if !isplay{
//                if index != musics.count-1{
//                    songPlayed = musics[index+1]
//                    configurePlayer(song: songPlayed!)
//                }else{
//                    songPlayed = musics[0]
//                    configurePlayer(song: songPlayed!)
//                }
//                player.pause()
//
//            }
//            else{
//                if index != musics.count-1{
//                    songPlayed = musics[index+1]
//                    configurePlayer(song: songPlayed!)
//                }else{
//                    songPlayed = musics[0]
//                    configurePlayer(song: songPlayed!)
//                }
//                player.play()
//            }
            
            
//            if index != musics.count-1{
//                songPlayed = musics[index+1]
//                configurePlayer(song: songPlayed!)
//            }else{
//                songPlayed = musics[0]
//                configurePlayer(song: songPlayed!)
//            }
//            player.play()
            
            if isplay == true {
                //目前單首的位置
                songPlayed = musics[musicIndex]
                //初始化的畫面設計
                configurePlayer(song: songPlayed!)
//                player.seek(to: pauseTime ?? CMTime(value: 0, timescale: 1))
//                print(player.currentTime())
//                player.play()
                print("播歌forwardButton",songPlayed!.musicName)
            }
            else{
                player.play()
                player.pause()
//                player.seek(to: pauseTime ?? CMTime(value: 0, timescale: 1))
//                print(player.currentTime())
                //目前單首的位置
                songPlayed = musics[musicIndex]
                //初始化的畫面設計
                configurePlayer(song: songPlayed!)
                print("暫停播歌forwardButton",songPlayed!.musicName)
            }
            print("goNext\(songPlayed!.musicName)",musicIndex)
        default:
            return
        }
        
        UIView.animate(withDuration: 0.25,animations: {
            buttonBackground.alpha = 0.0
            buttonBackground.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            sender.transform = CGAffineTransform.identity
            print("動畫有進來這裡1")
            
        }) { (_) in
            buttonBackground.transform = CGAffineTransform.identity
            print("動畫有進來這裡2")
        }
        
    }
    
    
    
    @IBAction func touchedDown(_ sender: UIButton) {
        let buttonBackground:UIView
        switch sender{
        case reverseButton:
            buttonBackground = reverseBackgroundView
        case playPauseButton:
            buttonBackground = playPauseBackgroundView
        case forwardButton:
            buttonBackground = forwardBackgroundView
        default:
            return
        }
        
        UIView.animate(withDuration: 0.25,delay: 0) {
            //View透明度
            buttonBackground.alpha = 0.1
            //縮小
            sender.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            print("動畫有進來這裡3")
        }
    }
    
    @IBAction func playSliderChanged(_ sender: UISlider) {
        
        //slider移動的數值
        let seconds = Int64(sender.value)
        //計算秒數
        // CMTimeMake會回傳一個 CMTime  能把 值跟經過的時間 綁在一起
        let targetTime = CMTimeMake(value: seconds, timescale: 1)
        
        
        //將player播放進度移至slider的位置所換算的秒數位置
        player.seek(to: targetTime)
        
        
        // true:滑動的時候音樂會中斷，false:滑動時音樂不中斷
        playingSlider.isContinuous = false
        
        
        // 設定slider移動後的圖示，normal為自動跑的時候，highlighted為使用者拖拉時的變化
        let normal = UIImage(named: "12")
        playingSlider.setThumbImage(normal, for: UIControl.State.normal)
        let highlighted = UIImage(named: "24")
        playingSlider.setThumbImage(highlighted, for: UIControl.State.highlighted)
    }
    
    
    
    @IBAction func volumeSliderChanged(_ sender: UISlider) {
        player.volume = sender.value
    }
    
}

