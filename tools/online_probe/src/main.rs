// Waldlust 온라인 상태 프로브 — RustDesk client::query_online_states 재현(hbb_common 재사용).
// rendezvous 서버(기본 127.0.0.1:21115)에 OnlineRequest를 보내고 OnlineResponse(상태 비트맵)를 읽어
// 온라인인 기기 ID만 한 줄씩 출력한다. cron이 이 출력으로 RDS를 갱신한다.
use hbb_common::{
    protobuf::Message,
    rendezvous_proto::{rendezvous_message, OnlineRequest, RendezvousMessage},
    socket_client,
};

#[hbb_common::tokio::main(flavor = "current_thread")]
async fn main() {
    let ids: Vec<String> = std::env::args().skip(1).collect();
    if ids.is_empty() {
        eprintln!("usage: wald-online-probe <id>...  (env ONLINE_SERVER=host:port, default 127.0.0.1:21115)");
        std::process::exit(1);
    }
    let server = std::env::var("ONLINE_SERVER").unwrap_or_else(|_| "127.0.0.1:21115".to_string());

    let mut msg = RendezvousMessage::new();
    msg.set_online_request(OnlineRequest {
        id: "waldadmin".to_string(),
        peers: ids.clone(),
        ..Default::default()
    });

    let mut socket = match socket_client::connect_tcp(server, 5000).await {
        Ok(s) => s,
        Err(e) => {
            eprintln!("connect failed: {e}");
            std::process::exit(2);
        }
    };
    if let Err(e) = socket.send(&msg).await {
        eprintln!("send failed: {e}");
        std::process::exit(3);
    }

    // 키교환 등 선행 메시지를 건너뛰며 OnlineResponse를 찾는다.
    for _ in 0..3 {
        match socket.next_timeout(5000).await {
            Some(Ok(bytes)) => {
                if let Ok(m) = RendezvousMessage::parse_from_bytes(&bytes) {
                    if let Some(rendezvous_message::Union::OnlineResponse(r)) = m.union {
                        let states = r.states;
                        for (i, id) in ids.iter().enumerate() {
                            // 바이트 내 MSB-first (RustDesk client과 동일)
                            let bit = 0x01u8 << (7 - (i % 8));
                            let online = states.get(i / 8).map(|b| b & bit == bit).unwrap_or(false);
                            if online {
                                println!("{id}");
                            }
                        }
                        return;
                    }
                }
            }
            _ => break,
        }
    }
    // 응답 없음 → 아무것도 출력 안 함(전부 오프라인 취급)
}
