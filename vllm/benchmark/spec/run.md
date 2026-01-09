I want to write the  shell script vllm/benchmark/vllm-bench/run.sh.

## Execution

### start vllm serving for this model

    vllm serve <nodel_name>

for some models, additional parameters are needed

    vllm serve mistralai/Mistral-Nemo-Instruct-2407 \
        --tokenizer_mode mistral \
        --config_format mistral \
        --load_format mistral

While the model load, we will capture and filter the log.
Typically we want to do an equilavent of:

    grep "Loading model weights"

Capture the model size (VRAM used by weights)

    grep -A 5 "ModelConfig"

Capture the model Parameter Count

We know that the server is started when we see "Application startup complete" in the logs

### start vllm bench 

    vllm bench serve --save-result --save-detailed \
      --backend vllm \
      --model <model_name> \
      --endpoint /v1/completions \
      --dataset-name custom \
      --dataset-path prompts.jsonl \
      --num-prompts 3 \
      --max-concurrency 1 \
      --temperature=0.3 \
      --top-p=0.75 \
      --result-dir "./logs/" \
      --request-rate inf

We want to pass additional parameters

  --max-concurrency 1
  --num-prompts 3  

##Configuration:

let's use a JSON or yaml configuration (whatever is easier to parse in shell).

### Concurrency

  --max-concurrency 1
  --num-prompts 3  

### Model Name

 - take a model name as parameter


### Per Model Config

 - allows to define additional vllm parameter for each model

Typically for `mistral/*` use 

    --tokenizer_mode mistral \
    --config_format mistral \
    --load_format mistral

We want to keep a copy of the configuration file for each run: copy and rename with current timestamp in logs directory.


-----

write the run.sh script and create a ReadMe.md at the same level to document how to use the script

