class VenuesController < ApplicationController
  def index
    filters_to_apply = params[:q]
    # If there are no defined filters, only show venues for the current user.
    if filters_to_apply.nil?
      filters_to_apply = {:fans_id_eq => current_user.id}
    else
      # If we are filtering by bookmarks, then limit it to bookmarks for this
      # user.
      if filters_to_apply.has_key?(:specialties_name_cont)
        filters_to_apply[:fans_id_eq] = current_user.id
      end
    end
    @q = Venue.ransack(filters_to_apply)
    @q.sorts = 'name_case_insensitive asc'
    @venues = @q.result(:distinct => true).includes(:bookmarks, :neighborhood, :fans, :specialties)
    @location_hash = Gmaps4rails.build_markers(@venues.where.not(:address_latitude => nil)) do |venue, marker|
      marker.lat venue.address_latitude
      marker.lng venue.address_longitude
      marker.infowindow "<h5><a href='/venues/#{venue.id}'>#{venue.created_at}</a></h5><small>#{venue.address_formatted_address}</small>"
    end

    render("venues/index.html.erb")
  end

  def show
    @bookmark = Bookmark.new
    @venue = Venue.find(params[:id])

    render("venues/show.html.erb")
  end

  def new
    @venue = Venue.new

    render("venues/new.html.erb")
  end

  def create
    @venue = Venue.new

    @venue.name = params[:name]
    @venue.address = params[:address]
    @venue.neighborhood_id = params[:neighborhood_id]

    save_status = @venue.save

    if save_status == true
      referer = URI(request.referer).path

      case referer
      when "/venues/new", "/create_venue"
        redirect_to("/venues")
      else
        redirect_back(:fallback_location => "/", :notice => "Venue created successfully.")
      end
    else
      render("venues/new.html.erb")
    end
  end

  def edit
    @venue = Venue.find(params[:id])

    render("venues/edit.html.erb")
  end

  def update
    @venue = Venue.find(params[:id])

    @venue.name = params[:name]
    @venue.address = params[:address]
    @venue.neighborhood_id = params[:neighborhood_id]

    save_status = @venue.save

    if save_status == true
      referer = URI(request.referer).path

      case referer
      when "/venues/#{@venue.id}/edit", "/update_venue"
        redirect_to("/venues/#{@venue.id}", :notice => "Venue updated successfully.")
      else
        redirect_back(:fallback_location => "/", :notice => "Venue updated successfully.")
      end
    else
      render("venues/edit.html.erb")
    end
  end

  def destroy
    @venue = Venue.find(params[:id])

    @venue.destroy

    if URI(request.referer).path == "/venues/#{@venue.id}"
      redirect_to("/", :notice => "Venue deleted.")
    else
      redirect_back(:fallback_location => "/", :notice => "Venue deleted.")
    end
  end
end
