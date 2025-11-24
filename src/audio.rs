use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};
use rustfft::FftPlanner;
use tokio::sync::broadcast;

pub fn start_audio_stream(tx: broadcast::Sender<Vec<f32>>) -> cpal::Stream {
    let host = cpal::default_host();
    let device = host.default_input_device().expect("No input device");
    let config = device.default_input_config().expect("No input config");

    let mut planner = FftPlanner::new();
    let fft = planner.plan_fft_forward(1024);

    let stream = device
        .build_input_stream(
            &config.into(),
            move |data: &[f32], _: &_| {
                let mut input = data.to_vec(); //buffer
                input.resize(1024, 0.0);

                let mut buffer: Vec<_> = input  // f32->Complex
                    .iter()
                    .map(|x| rustfft::num_complex::Complex::new(*x, 0.0))
                    .collect();
                fft.process(&mut buffer);       // real magic

                let magnitude: Vec<f32> = buffer
                    .iter()
                    .take(512)                  //symmetric
                    .map(|c| c.norm().ln_1p())  //magnitude, compress loudness
                    .collect();

                let _ = tx.send(magnitude);     //brodcast
            },
            |err| eprintln!("Audio error: {}", err),
            None,
        )
        .unwrap();

    stream.play().unwrap();
    stream
}

//sample rate = 16000 samples/s
//time = 1024/16000 = 64 ms