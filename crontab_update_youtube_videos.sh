while read p; do
  export $p
done </app/.prod.env

/app/Run updateYoutubeVideos -r false