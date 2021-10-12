reticulate::use_virtualenv("/home/waldo/PycharmProjects/forR/venv/", required = TRUE)
reticulate::repl_python()

import glob
import numpy as np
import pandas as pd
import zipfile

archive = zipfile.ZipFile("./data/raw/obs/AWS/PC_hourly_QC.zip", 'r')

ema_xyz = pd.read_csv(archive.open('pc_xyz.csv'))
ema_data = pd.read_csv(archive.open('pc_qc_values.csv'), parse_dates=True, index_col=0)

ema_xyz = ema_xyz[~((ema_xyz["LON"] < -80) & (ema_xyz["LAT"] < -6))]
ema_xyz.reset_index(drop=True, inplace=True)
ema_xyz.iloc[168,2] = ema_xyz.iloc[168,2] + 0.05
ema_xyz.iloc[168,3] = ema_xyz.iloc[168,3] + 0.05
ema_data = ema_data.drop("X4720A6CC", axis=1)

res = pd.concat([pd.Series(ema_data.columns.to_list()), ema_xyz["CODE"]], axis = 1)
res.columns = ["data", "CODE"]
res["EQUAL"] = res.apply(lambda x: x.data == x.CODE, axis=1)
res[res["EQUAL"] == False]


#ema_data_shifted_rr = []
ema_data_shifted = []

for station in ema_data.columns:
  
  hourly_p = ema_data[station]
  hourly_p = hourly_p.shift(periods=-8, freq="H")["2014-01-01":"2020-12-31"]
  #daily_p = hourly_p.resample("1D").apply(lambda x: x.sum() if x.isnull().sum() < 1 else np.nan)
  #daily_p = daily_p.repeat(24)
  #daily_p.index = hourly_p.index
  
  #ema_data_shifted_rr.append((hourly_p + 0.000001) * 100/ (daily_p + 0.000001) )
  ema_data_shifted.append(hourly_p)

#ema_data_shifted_rr = pd.concat(ema_data_shifted_rr, axis=1)
ema_data_shifted = pd.concat(ema_data_shifted, axis=1)


#np.round(ema_data_shifted_rr, 2).to_csv("/content/drive/MyDrive/Google_Colab_temp/ema_data_rr_77.csv")
np.round(ema_data_shifted, 1).to_csv("./data/processed/obs/AWS/AWS_data.csv")
ema_xyz.to_csv("./data/processed/obs/AWS/AWS_xyz.csv")
