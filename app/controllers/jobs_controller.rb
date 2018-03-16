class JobsController < ApplicationController
  before_action :set_job, only: [:show, :result]

  # GET /jobs
  def index
    @jobs = Job.all

    render json: @jobs
  end

  # GET /jobs/1
  def show
    render json: @job
  end

  # GET /jobs/1/result
  def result
    # TODO retrieve actual result when present
    # return 400 if status != finished
    render plain: S3Store.read(@job.model_path)
  end

  # POST /jobs
  def create

    # decode model data
    model = Base64.decode64(job_params[:model])

    # TODO upload to S3
    goal = job_params[:goal]
    user = job_params[:user]
    model_path = "user-#{user}-goal-#{goal}-#{Time.now.to_i}"
    S3Store.store(model_path, model)

    @job = Job.new(user: job_params[:user], goal: job_params[:goal], model_path: model_path)

    if @job.save
      # TODO enqueue in SQS
      render json: @job, status: :created, location: @job
    else
      render json: @job.errors, status: :unprocessable_entity
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_job
      @job = Job.find(params[:id])
      # TODO Check if solution is present in S3
    end

    # Only allow a trusted parameter "white list" through.
    def job_params
      # TODO This is giving "Unpermitted parameter: :job" because we're using a custom parameter that's not in the model
      params.permit(:user, :goal, :model)
    end
end
