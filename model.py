from pydantic import BaseModel
from transformers import AutoTokenizer, AutoModelForTokenClassification, AutoModelForSequenceClassification
from transformers import pipeline

from fastapi import FastAPI

app = FastAPI()

NER_tokenizer = AutoTokenizer.from_pretrained("dslim/bert-base-NER")
NER_model = AutoModelForTokenClassification.from_pretrained(
    "dslim/bert-base-NER")

get_entity = pipeline("ner", model=NER_model, tokenizer=NER_tokenizer)

SPAM_tokenizer = AutoTokenizer.from_pretrained(
    "mariagrandury/roberta-base-finetuned-sms-spam-detection")

SPAM_model = AutoModelForSequenceClassification.from_pretrained(
    "mariagrandury/roberta-base-finetuned-sms-spam-detection")


def is_spam(text):
    inputs = SPAM_tokenizer(text, return_tensors="pt")
    outputs = SPAM_model(**inputs)
    predicted_label = outputs.logits.argmax().item()
    return predicted_label


class Input(BaseModel):
    text: str


@app.post("/")
async def root(input: Input):
    return {
        "spam": is_spam(input.text),
        "itentity": str(get_entity(input.text))
    }
