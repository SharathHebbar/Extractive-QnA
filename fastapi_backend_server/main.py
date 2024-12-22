
import torch
from transformers import (
    BertForQuestionAnswering,
    BertTokenizerFast,
)

from scipy.special import softmax

import pandas as pd
import numpy as np

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel


model_name = 'deepset/bert-base-uncased-squad2'

model = BertForQuestionAnswering.from_pretrained(model_name)
tokenizer = BertTokenizerFast.from_pretrained(model_name)

app = FastAPI()



app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods
    allow_headers=["*"],  # Allow all headers
)

def predict_answer(context, question):
    inputs = tokenizer(question, context, return_tensors="pt", truncation=True, max_length=512)
    with torch.no_grad():
        outputs = model(**inputs)

    start_scores, end_scores = softmax(outputs.start_logits)[0], softmax(outputs.end_logits)[0]
    start_idx = np.argmax(start_scores)
    end_idx = np.argmax(end_scores)

    confidence_score = (start_scores[start_idx] + end_scores[end_idx]) / 2
    answer_ids = inputs.input_ids[0][start_idx: end_idx + 1]
    answer_tokens = tokenizer.convert_ids_to_tokens(answer_ids)
    answer = tokenizer.convert_tokens_to_string(answer_tokens)
    if answer != tokenizer.cls_token:
        return {
            "answer": answer, 
            "score": confidence_score
        }
    else:
        return {
            "answer": "No answer found.", 
            "score": confidence_score
        }

# Define the request model
class QnARequest(BaseModel):
    context: str
    question: str

# Define the response model
class QnAResponse(BaseModel):
    answer: str
    confidence: float


@app.post("/qna", response_model=QnAResponse)
async def extractive_qna(request: QnARequest):
    context = request.context
    question = request.question
    # print(context, question)
    if not context or not question:
        raise HTTPException(status_code=400, detail="Context and question cannot be empty.")

    try:
        result = predict_answer(context, question)
        print(result)
        return QnAResponse(answer=result["answer"], confidence=result["score"])
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing QnA: {str(e)}")
