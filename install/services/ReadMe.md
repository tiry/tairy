
## Driver checks

    amd-smi firmware

    amd-smi --help |grep -i version

    amdgpu_top
    
     rocm-smi -i


## llama.ccp

     /home/tiry/llama.cpp/build/bin/llama-server --model /home/tiry/llama.cpp/models/gpt-oss-120b-Q5_K_M-00001-of-00002.gguf --ctx-size 8192 --gpu-layers 37 --batch-size 256 --port 39595 --no-webui --flash-attn on --rope-freq-scale 0.03125 --rope-freq-base 150000


## Agent0


    cd dev
    docker run -p 50001:80 -v ./a0:/a0 agent0ai/agent-zero
 

## Chat WebUI


    /etc/systemd/system/chat-webui.service

Reload config

    sudo systemctl enable --now chat-webui.service
    systemctl daemon-reload

Restart
    sudo systemctl restart chat-webui

Check Status 
    journalctl -u chat-webui -f


