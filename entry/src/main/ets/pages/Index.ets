import { VideoController } from '../controller/VideoController'
import { PlayerModel } from '../model/PlayerModel'
import { media } from '@kit.MediaKit'

@Entry
@Component
struct Index {
  /**视频控制器*/
  videoController: VideoController = new VideoController()
  /**XComponent控制器*/
  controller: XComponentController = new XComponentController()
  /**视频参数数据模型*/
  @State playerModel: PlayerModel = this.videoController.playerModel
  /**本地文件名称*/
  @State fdSrcName: string = 'go_home.mp4'
  /**网络视频路径*/
  @State url: string = ''

  build() {
    Column() {
      XComponent({
        id: "", // 唯一标识
        type: XComponentType.SURFACE, // 组件类型 surface component
        controller: this.controller
      })
        .onLoad(async () => {
          // 设置XComponent持有Surface的宽度和高度
          await this.controller!.setXComponentSurfaceSize({
            surfaceWidth: 1980,
            surfaceHeight: 1080
          })

          // 获取 XComponent的SurfaceId 用于关联视频画面
          let surfaceId = this.controller.getXComponentSurfaceId()
          // 调用播放视频方法 关联视频
          this.videoController.playFdSrc(surfaceId, this.fdSrcName)
        })
        .width(this.playerModel.videoWidth)
        .height(this.playerModel.videoHeight)
      Column() {
        Row({ space: 4 }) {
          Button("播放/暂停")
            .onClick(() => {
              this.videoController.switchPlayOrPause()
            })
          Button("重播")
            .onClick(() => {
              this.videoController.play()
            })
            .enabled(this.playerModel.currentTime >= this.playerModel.totalTime)
        }.padding(6)

        Slider({
          value: this.playerModel.progressVal,
          step: 1,
          style: SliderStyle.OutSet
        })
          .blockColor(Color.White)
          .trackColor("#888888")
          .onChange((value: number, mode: SliderChangeMode) => {
            this.videoController.setSeekTime(value, mode)
          })
        Text("当前进度:" +
        this.playerModel.currentTime
        )
          .fontColor(Color.White)

        Text("总时长:" +
        this.playerModel.totalTime
        )
          .fontColor(Color.White)
        Row() {
          Button("1x")
            .onClick(() => {
              this.videoController.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_00_X)
            })
          Button("1.5x")
            .onClick(() => {
              this.videoController.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_50_X)
            })
          Button("2x")
            .onClick(() => {
              this.videoController.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_2_00_X)
            })
        }
      }
    }
    .justifyContent(this.playerModel.videoPosition)
    .backgroundColor(Color.Black)
    .height('100%')
    .width('100%')
  }
}