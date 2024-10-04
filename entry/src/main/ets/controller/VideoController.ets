import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { PlayerModel } from '../model/PlayerModel'
import { common, dataUriUtils } from '@kit.AbilityKit';
import DateFormatUtil from '../common/DateFormatUtil';

@Observed
export class VideoController {
  public playerModel: PlayerModel
  private surfaceId: string = ''; // surfaceID用于播放画面显示，具体的值需要通过Xcomponent接口获取，相关文档链接见上面Xcomponent创建方法
  public avPlayer: media.AVPlayer | null = null
  private fdSrc: string = '' // 本地资源url
  private url: string = '' // 网络资源url
  private status: number = 1
  private seekTime: number = 0
  private duration: number = 0

  constructor() {
    this.playerModel = new PlayerModel()
    this.createAVPlayer()
  }

  // 创建 AVPlayer 实例
  async createAVPlayer() {
    let avPlayer: media.AVPlayer = await media.createAVPlayer();
    this.avPlayer = avPlayer;
    this.bindState()
  }

  bindState() {
    if (!this.avPlayer) {
      return
    }
    // seek操作结果回调函数
    this.avPlayer.on('seekDone', (seekDoneTime: number) => {
      console.info(`AVPlayer seek succeeded, seek time is ${seekDoneTime}`);
    })
    // error回调监听函数,当avPlayer在操作过程中出现错误时调用 reset接口触发重置流程
    this.avPlayer.on('error', (err: BusinessError) => {
      if (!this.avPlayer) {
        return
      }
      console.error(`Invoke avPlayer failed, code is ${err.code}, message is ${err.message}`);
      this.avPlayer.reset(); // 调用reset重置资源，触发idle状态
    })

    // 监听进度条播放
    this.avPlayer.on("timeUpdate", (time) => {
      this.changeProgress(time)
    })

    // 状态机变化回调函数
    this.avPlayer.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
      if (!this.avPlayer) {
        return
      }
      switch (state) {
        case 'idle': // 成功调用reset接口后触发该状态机上报
          console.info('AVPlayer state idle called.');
          this.avPlayer.release(); // 调用release接口销毁实例对象
          break;
        case 'initialized': // avplayer 设置播放源后触发该状态上报
          console.info('AVPlayer state initialized called.');
          this.avPlayer.surfaceId = this.surfaceId
          this.avPlayer.prepare();
          break;
        case 'prepared': // prepare调用成功后上报该状态机
          console.info('AVPlayer state prepared called.');
          this.setVideoSize()
          this.avPlayer.play(); // 调用播放接口开始播放
          this.duration = this.avPlayer.duration
          break;
        case 'playing': // play成功调用后触发该状态机上报
          console.info('AVPlayer state playing called.');
          this.status = 1
          break;
        case 'paused': // pause成功调用后触发该状态机上报
          console.info('AVPlayer state paused called.');
          this.status = 2
          break;
        case 'completed': // 播放结束后触发该状态机上报
          console.info('AVPlayer state completed called.');
          break;
        case 'stopped': // stop接口成功调用后触发该状态机上报
          console.info('AVPlayer state stopped called.');
          this.avPlayer.reset(); // 调用reset接口初始化avplayer状态
          break;
        case 'released':
          console.info('AVPlayer state released called.');
          break;
        default:
          console.info('AVPlayer state unknown called.');
          break;
      }
    })
  }

  /**
   * 播放本地接口
   * @param surfaceId surfaceId 通过XComponent获取
   * @param fdSrcName 本地资源名称
   */
  async playFdSrc(surfaceId: string, fdSrcName: string) {
    this.surfaceId = surfaceId
    if (this.avPlayer === null) {
      await this.createAVPlayer();
    }
    if (this.avPlayer !== null) {
      let context = getContext(this) as common.UIAbilityContext
      let fileDescriptor = await context.resourceManager.getRawFd(fdSrcName)
      console.log("fileDescriptor:" + fileDescriptor)
      this.avPlayer.fdSrc = fileDescriptor
    }
  }

  /**
   * 播放网络资源
   * @param surfaceId surfaceId 通过XComponent获取
   * @param url 网络资源url
   */
  async playUrl(surfaceId: string, url: string) {
    this.surfaceId = surfaceId
    if (this.avPlayer === null) {
      await this.createAVPlayer();
    }
    if (this.avPlayer !== null) {
      this.avPlayer.url = url;
    }
  }


  /**
   * 根据视频大小设置播放页面大小
   */
  setVideoSize() {
    if (this.avPlayer === null) {
      return;
    }
    if (this.avPlayer.height > this.avPlayer.width) {
      this.playerModel.videoWidth = '100%';
      this.playerModel.videoHeight = '100%';
      this.playerModel.videoPosition = FlexAlign.Center;
      this.playerModel.videoMargin = '7.2%';
    } else {
      this.playerModel.videoWidth = "100%"
      this.playerModel.videoHeight = '25.6%';
      this.playerModel.videoPosition = FlexAlign.Center;
      this.playerModel.videoMargin = '0';
    }
  }

  play() {
    if (this.avPlayer !== null) {
      this.avPlayer.play();
    }
  }

  pause() {
    if (this.avPlayer !== null) {
      this.avPlayer.pause();
    }
  }

  switchPlayOrPause() {
    if (this.avPlayer === null) {
      return;
    }
    if (this.status === 1) {
      this.avPlayer.pause();
    } else {
      this.avPlayer.play();
    }
  }

  /**
   * 修改进度条
   * @param time
   */
  changeProgress(time: number) {
    // 将当前进度毫秒数转换为秒
    let nowSeconds = Math.floor(time / 1000)
    // 将当前视频总毫秒数转换为 总秒数
    let totalSeconds = Math.floor(this.duration / 1000)
    this.playerModel.currentTime = DateFormatUtil.secondToTime(nowSeconds)
    this.playerModel.totalTime = DateFormatUtil.secondToTime(totalSeconds)
    this.playerModel.progressVal = Math.floor(nowSeconds * 100 / totalSeconds)
    console.log("progressVal:" + this.playerModel.progressVal)
  }




  /**
   * 设置跳转时间
   * @param value
   * @param mode
   */
  setSeekTime(value: number, mode: SliderChangeMode) {
    // 判断当前 Slider 的模式 是否是移动中
    if (mode === SliderChangeMode.Moving) {
      // 如果是移动中，更新进度值和当前时间显示
      this.playerModel.progressVal = value
      // 将 value 乘以 duration 再进行处理后转换为时间格式
      this.playerModel.currentTime = DateFormatUtil.secondToTime(Math.floor(value * this.duration / 100 / 1000))
      this.avPlayer?.play()
    }

    if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
      // 如果是结束或点击模式，计算跳转时间并调用 avPlayer 的 seek 方法进行跳转
      this.seekTime = value * this.duration / 100
      if (this.avPlayer !== null) {
        this.avPlayer.seek(this.seekTime, media.SeekMode.SEEK_NEXT_SYNC)
        this.avPlayer.play()
      }
    }
  }
  setSpeed(playSpeed: media.PlaybackSpeed) {
    this.playerModel.playSeed = playSpeed

    this.avPlayer?.setSpeed(this.playerModel.playSeed)
  }
}