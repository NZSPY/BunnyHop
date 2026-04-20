gcloud config set project bunny-hop-nz
gcloud run deploy bunnyhopnz --source . --region=us-central1 --min-instances=0 --max-instances=1