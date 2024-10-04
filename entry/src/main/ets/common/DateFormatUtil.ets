/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

class DateFormatUtil {
  /**
   * 将给定的秒数转换为格式化的时间字符串。
   * @function secondToTime
   * @param {number} seconds - 要转换的秒数。
   * @returns {string} 格式化后的时间字符串，格式为“小时:分钟:秒”。如果小时数为 0，则只显示“分钟:秒”；如果分钟数也为 0，则显示“00:秒”。
   */
  secondToTime(seconds: number): string {
    let hourUnit = 60 * 60;
    let hour = Math.floor(seconds / hourUnit);
    let minute = Math.floor((seconds - hour * hourUnit) / 60);
    let second = seconds - hour * hourUnit - minute * 60;
    if (hour > 0) {
      return `${this.padding(hour.toString())}:
        ${this.padding(minute.toString())}:${this.padding(second.toString())}`;
    }
    if (minute > 0) {
      return `${this.padding(minute.toString())}:${this.padding(second.toString())}`;
    } else {
      return `00:${this.padding(second.toString())}`;
    }
  }

  /**
   * 对给定的数字字符串进行前导零填充，确保字符串长度为 2。
   * @param {string} num - 要进行填充的数字字符串。
   * @returns {string} 长度为 2 的字符串，如果传入的字符串长度小于 2，则在前面填充零。
   */
  padding(num: string): string {
    return num.padStart(2,'0');
  }
}

export default new DateFormatUtil();